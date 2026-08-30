variable "cluster_name" {
  description = "k3d cluster name."
  type        = string
  default     = "posts-cluster"
}

variable "agent_count" {
  description = "Number of k3d agent (worker) nodes. One per zone in `zones`."
  type        = number
  default     = 3
}

variable "zones" {
  description = "Availability-zone label applied to each agent node (agent-0 gets zones[0], and so on), so topologySpreadConstraints in the chart actually has something to spread across."
  type        = list(string)
  default     = ["zone-a", "zone-b", "zone-c"]
}

variable "lb_http_port" {
  description = "Host port forwarded to the cluster's ingress (port 80) via the k3d load balancer."
  type        = number
  default     = 8080
}

variable "lb_https_port" {
  description = "Host port forwarded to the cluster's ingress (port 443) via the k3d load balancer."
  type        = number
  default     = 8443
}

variable "app_namespace" {
  description = "Namespace Argo CD deploys posts-api into. Must match gitops/application.yaml's spec.destination.namespace."
  type        = string
  default     = "posts-api-gitops"
}

variable "argocd_chart_version" {
  description = "argo-helm `argo-cd` chart version. Empty string = latest."
  type        = string
  default     = ""
}

variable "argo_rollouts_chart_version" {
  description = "argo-helm `argo-rollouts` chart version. Empty string = latest."
  type        = string
  default     = ""
}

variable "dockerhub_username" {
  description = "Docker Hub username used to pull the (private) posts-api image. Populates the `regcred` imagePullSecret."
  type        = string
  sensitive   = true
}

variable "dockerhub_password" {
  description = "Docker Hub access token (Read-only is enough) for the `regcred` imagePullSecret."
  type        = string
  sensitive   = true
}
