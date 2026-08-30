# AWS environment (Terraform) — stub, not applied

Covers the challenge's optional goal of also using Terraform for a remote
environment. **This module is illustrative and has never been `apply`'d**
— the challenge explicitly says not to incur cloud costs, and an EKS
cluster plus its NAT gateways/load balancers do cost money the moment
they exist, regardless of traffic. Treat this as "here's how the local
setup would translate to a real cloud provider," reviewed for structure
and cost-consciousness, not as a running environment.

## What it provisions (on paper)

- A VPC across 3 AZs (`terraform-aws-modules/vpc`), one public + one
  private subnet per AZ, one NAT gateway per AZ (so one AZ's NAT going
  down doesn't cut egress for the other two — same HA reasoning as the
  challenge's "3 AZs" requirement).
- An EKS cluster (`terraform-aws-modules/eks`) with a managed node group,
  3 nodes minimum (one per AZ) autoscaling up to 6.

## What it deliberately leaves out

- **No remote backend configured.** Applying this for real needs an S3
  bucket + DynamoDB lock table (or Terraform Cloud) added to
  `versions.tf` first — state for a shared cloud resource has no business
  living on a laptop.
- **No Argo CD / posts-api bootstrap**, unlike `../local`. Once a real
  cluster existed, the same `kubernetes_secret.regcred` /
  `database.existingSecret` pattern from `../local/posts-api.tf` would
  apply verbatim; it's left out here so this stays a pure infrastructure
  module — bootstrapping the app is a second, deliberate step against a
  cluster someone has actually decided to pay for.
- **No cost estimate / budget alarms.** Before ever running `apply`
  against this, get a `terraform plan` cost estimate (e.g. Infracost) and
  set a billing alarm.

## If you do decide to apply it

```sh
cd terraform/aws
terraform init
terraform plan   # review carefully — this creates billable resources
terraform apply
aws eks update-kubeconfig --region <region> --name posts-api
```

And to tear it back down when done (NAT gateways in particular bill
hourly even when idle):

```sh
terraform destroy
```
