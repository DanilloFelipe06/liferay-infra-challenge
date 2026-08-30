# Local environment (Terraform)

Reproduces, from nothing, the local k3d setup this repo has been developed
against: a 3-agent k3d cluster with one agent per (fake) availability zone,
Argo CD, Argo Rollouts, and the bootstrap objects (namespace + Secrets)
that `gitops/application.yaml` needs before Argo CD can take over and
deploy `charts/posts-api` on its own.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [k3d](https://k3d.io) (creates the cluster; there's no Terraform provider for it)
- Docker running locally
- A Docker Hub username + access token that can pull `danillofelipe/posts-api-private`

## Usage

```sh
cd terraform/local
terraform init
cp terraform.tfvars.example terraform.tfvars   # then fill in your Docker Hub creds

# 1) bring up the cluster first. The kubernetes/helm/kubectl providers
#    below need a real kubeconfig file to validate at plan time, which
#    only exists after this resource runs — a two-step apply is the usual
#    way around that specific chicken-and-egg (cluster-creation-in-the-
#    same-config-that-uses-it) limitation.
terraform apply -target=null_resource.k3d_cluster

# 2) now everything else: Argo CD, Argo Rollouts, the posts-api namespace
#    and its Secrets, and the Argo CD Application that hands the rest of
#    the reconciliation over to git.
terraform apply
```

This is idempotent — re-running `apply` against an already-existing k3d
cluster of the same name reuses it instead of recreating it.

Once applied:

```sh
export KUBECONFIG=$(terraform output -raw kubeconfig_path)
kubectl -n posts-api-gitops get pods         # Argo CD syncing charts/posts-api
terraform output -raw argocd_admin_password  # Argo CD UI/CLI login
curl $(terraform output -raw app_url)
```

Argo CD then reconciles `posts-api-gitops` from this repo's `main` branch
on its own — the CI/CD pipeline in
[.github/workflows/build-and-deploy.yml](../../.github/workflows/build-and-deploy.yml)
is what actually changes what gets deployed from here on, not another
`terraform apply`.

## Teardown

```sh
terraform destroy
```

Deletes the k3d cluster (and everything in it) along with the Terraform-managed state.

## What this deliberately does *not* do

- **Install an ingress controller** — k3d ships Traefik by default as part
  of the bundled k3s, so `charts/posts-api`'s `Ingress` (see
  `values.yaml`'s `ingress.className: traefik`) works out of the box.
- **Manage the DB credentials Secret's *contents* across `apply`s** —
  `random_password` generates them once; Terraform won't rotate them on a
  later `apply` since that's exactly the class of drift documented in
  `charts/posts-api/values.yaml` (`database.existingSecret`). If you ever
  need to rotate them, do it deliberately (`terraform taint
  random_password.db_password`), not as a side effect of routine applies.
