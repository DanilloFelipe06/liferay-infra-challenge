# Terraform

Two independent root modules, not a single multi-environment setup with
shared modules — the local and cloud cases have different enough concerns
(no cost/backend story locally, no cluster-creation-CLI story in the
cloud) that forcing them into one shared module would mostly add
indirection.

- **[local/](local/)** — actually used, actually applied. Stands up the
  k3d cluster, Argo CD, Argo Rollouts, and the posts-api bootstrap
  (namespace + Secrets) this repo has been developed against.
- **[aws/](aws/)** — a stub covering the optional "use Terraform for a
  remote environment" goal. Written and `validate`'d, never `apply`'d —
  see its README for why.
