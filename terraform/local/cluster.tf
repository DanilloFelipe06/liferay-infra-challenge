# There is no maintained Terraform provider for k3d itself, so the cluster
# is created with the k3d CLI via local-exec (idempotent: skips creation if
# a cluster with this name already exists) and its kubeconfig is written to
# a file *local to this module* — not merged into ~/.kube/config — which
# every other provider/resource in this module then points at.
resource "null_resource" "k3d_cluster" {
  triggers = {
    cluster_name = var.cluster_name
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      if ! k3d cluster get "${var.cluster_name}" >/dev/null 2>&1; then
        k3d cluster create "${var.cluster_name}" \
          --servers 1 \
          --agents ${var.agent_count} \
          --port "${var.lb_http_port}:80@loadbalancer" \
          --port "${var.lb_https_port}:443@loadbalancer" \
          %{for idx, zone in var.zones~}
          --k3s-node-label "topology.kubernetes.io/zone=${zone}@agent:${idx}" \
          %{endfor~}
          --wait
      fi

      k3d kubeconfig write "${var.cluster_name}" --output "${path.module}/kubeconfig.yaml"
    EOT
  }

  provisioner "local-exec" {
    when       = destroy
    command    = "k3d cluster delete ${self.triggers.cluster_name} || true"
    on_failure = continue
  }
}

locals {
  kubeconfig_path = "${path.module}/kubeconfig.yaml"
}
