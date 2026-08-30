data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # Always exactly 3 AZs, mirroring the local k3d module's 3 zone-labeled
  # agents and the challenge's "3 availability zones" HA requirement.
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

# --- Networking -------------------------------------------------------
# One public + one private subnet per AZ. Nodes/pods live in the private
# subnets; a NAT gateway per AZ gives them egress without exposing them
# directly. This is the standard, well-trodden path for this module (as
# opposed to hand-rolling VPC resources) — pinning an exact version is
# what keeps `terraform init` reproducible.
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr
  azs  = local.azs

  public_subnets  = [for i, az in local.azs : cidrsubnet(var.vpc_cidr, 8, i)]
  private_subnets = [for i, az in local.azs : cidrsubnet(var.vpc_cidr, 8, i + 10)]

  enable_nat_gateway   = true
  single_nat_gateway   = false # one NAT per AZ: an AZ outage doesn't take egress down for the others
  enable_dns_hostnames = true

  # Required so the AWS Load Balancer Controller / EKS's own controllers
  # can discover which subnets to place load balancers in.
  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# --- EKS cluster --------------------------------------------------------
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.24.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    default = {
      instance_types = [var.node_instance_type]
      min_size       = var.node_group_min_size
      max_size       = var.node_group_max_size
      # One node per AZ to start: matches the local module's 1-agent-per-
      # zone layout and gives topologySpreadConstraints in the chart an
      # actual spread to enforce from the first node up.
      desired_size = var.node_group_min_size

      subnet_ids = module.vpc.private_subnets
    }
  }

  # posts-api's Helm values (charts/posts-api/values.yaml) pull a private
  # Docker Hub image via a regcred imagePullSecret, and read DB credentials
  # from a Secret it never generates itself (database.existingSecret) —
  # both created out-of-band, same as the local module's
  # kubernetes_secret.regcred / db_credentials. Reuse that same pattern
  # here (kubernetes provider pointed at this cluster) rather than
  # re-deriving it; omitted from this stub to keep it a pure
  # infrastructure module.
}
