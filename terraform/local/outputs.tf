output "kubeconfig_path" {
  description = "Path to this module's standalone kubeconfig. Use it directly (kubectl --kubeconfig=<path> ...) or `export KUBECONFIG=<path>`."
  value       = local.kubeconfig_path
}

output "argocd_admin_password" {
  description = "Argo CD initial admin password. Log in with `argocd login localhost:8443 --username admin --insecure` (after `kubectl -n argocd port-forward svc/argocd-server 8443:443`) or through the UI."
  value       = data.kubernetes_secret.argocd_admin_password.data["password"]
  sensitive   = true
}

output "app_url" {
  description = "Where posts-api is reachable once Argo CD has synced (see ingress.host in charts/posts-api/values.yaml — empty host = catch-all, so any Host header works against the k3d load balancer)."
  value       = "http://localhost:${var.lb_http_port}/posts"
}
