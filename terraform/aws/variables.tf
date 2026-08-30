variable "aws_region" {
  description = "AWS region to deploy into. Must have at least 3 AZs."
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
  default     = "posts-api"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS control plane."
  type        = string
  default     = "1.30"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "node_instance_type" {
  description = "Instance type for the managed node group. t3.medium is the smallest type with enough headroom for the EKS-required daemonsets plus a few app pods."
  type        = string
  default     = "t3.medium"
}

variable "node_group_min_size" {
  description = "Minimum node count for the managed node group — kept at 3 (one per AZ) to mirror the HA requirement the local k3d cluster demonstrates."
  type        = number
  default     = 3
}

variable "node_group_max_size" {
  description = "Maximum node count the autoscaler-managed group can grow to."
  type        = number
  default     = 6
}
