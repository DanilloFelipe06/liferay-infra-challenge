# All three providers read the kubeconfig that null_resource.k3d_cluster
# writes out. The file doesn't need to exist at plan time — only when a
# resource from that provider is actually applied, by which point the
# cluster resource (an implicit or explicit dependency of every resource
# below) has already run.
provider "kubernetes" {
  config_path = local.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = local.kubeconfig_path
  }
}

provider "kubectl" {
  config_path      = local.kubeconfig_path
  load_config_file = true
}
