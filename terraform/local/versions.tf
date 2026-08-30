terraform {
  required_version = ">= 1.5"

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.31"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.14"
    }
    # CRDs (Argo CD's Application, in particular) aren't known to the
    # Kubernetes provider's built-in schema, and `kubernetes_manifest`
    # needs the cluster reachable at plan time to resolve them. `kubectl`
    # applies raw YAML server-side instead, sidestepping both problems —
    # a good fit for a resource we bring up in the same apply as the
    # cluster and CRDs it depends on.
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.0"
    }
  }
}
