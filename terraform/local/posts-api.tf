# Everything in this file is the "bootstrap" step documented at the top of
# gitops/application.yaml: the handful of things that must exist *before*
# Argo CD takes over, because Argo CD itself (by design, via
# database.existingSecret / imagePullSecrets — see charts/posts-api/values.yaml)
# never creates or touches them. Terraform is standing in for the
# `kubectl create namespace` / `kubectl create secret` commands from that
# comment; from here on, git + Argo CD's auto-sync is what actually
# reconciles the namespace's contents.

resource "kubernetes_namespace" "posts_api" {
  metadata {
    name = var.app_namespace
  }
  depends_on = [null_resource.k3d_cluster]
}

resource "kubernetes_secret" "regcred" {
  metadata {
    name      = "regcred"
    namespace = kubernetes_namespace.posts_api.metadata[0].name
  }
  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "https://index.docker.io/v1/" = {
          username = var.dockerhub_username
          password = var.dockerhub_password
          auth     = base64encode("${var.dockerhub_username}:${var.dockerhub_password}")
        }
      }
    })
  }
}

# See the long comment on database.existingSecret in charts/posts-api/values.yaml
# for why this Secret is deliberately created out-of-band instead of by the
# Helm chart. random_password (not the chart) owns these values; Argo CD's
# sync never generates or overwrites them.
resource "random_password" "db_password" {
  length  = 24
  special = false
}

resource "random_password" "db_root_password" {
  length  = 24
  special = false
}

resource "kubernetes_secret" "db_credentials" {
  metadata {
    name      = "posts-api-db-credentials"
    namespace = kubernetes_namespace.posts_api.metadata[0].name
  }

  data = {
    TYPEORM_USERNAME    = "posts_app"
    TYPEORM_DATABASE    = "posts"
    TYPEORM_PASSWORD    = random_password.db_password.result
    MYSQL_ROOT_PASSWORD = random_password.db_root_password.result
  }
}

# The Argo CD Application itself — applying this is the one-time handoff
# from "Terraform manages this" to "git + Argo CD manages this". The
# manifest is read straight from gitops/application.yaml so there's a
# single source of truth for it instead of a copy drifting in Terraform.
resource "kubectl_manifest" "posts_api_application" {
  yaml_body = file("${path.module}/../../gitops/application.yaml")

  depends_on = [
    helm_release.argocd,
    helm_release.argo_rollouts,
    kubernetes_namespace.posts_api,
    kubernetes_secret.regcred,
    kubernetes_secret.db_credentials,
  ]
}
