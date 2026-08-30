# Cloud Infrastructure Interview test

The goal of this test is to "containerize" a sample application and write the necessary code to run it in a kubernetes cluster.

## Delivery

To submit the code, publish it to a public github repository, or a zipped file with all the contents that allow the code to be executed. Feel free to add a README.md file with instructions.

## Evaluation Criteria

The code you submit will be used in the technical interview, and you will be questioned about decisions made on the implementation.

The code in this repository is written in a way to make local development easier, which makes for bad practices when running it in a remote environment like a production server.
Change (add, move, remove, modify, etc) any files in this repository to fulfill the requirements on the next section, while delivering **production grade** code, with what you understand are best practices, considering a project that will be maintained by multiple people
of different nationalities, and run 24/7 in a global scale.
While the goal is to containerize the application and deploy it to kubernetes, any change to the provided application that you deem necessary to fulfill the criteria is also valid.
To highlight a few criteria, in no particular order:

- Code organization
- Documentation
- Change history
- Tests
- Release and deployment mechanisms
- Security
- Performance
- Availability
- Cost
- Industry best practices

## Requirements

Submissions that do not contain these requirements will be automatically disconsidered:

1. Create a container image with the application in this repository and publish it in a public repository (dockerhub, quay, etc);
2. Write all the code you feel necessary to deploy the image in a kubernetes cluster;
3. Expose the application externally to the kubernetes cluster;
4. Configure the application to be deployed in a highly available setup, considering the cluster has worker nodes in 3 different availability zones;

## Testing

To test this, use any free local kubernetes distribution, like [minikube](https://github.com/kubernetes/minikube), [kind](https://kind.sigs.k8s.io/), [k3d](https://k3d.io), etc.
There is no need to run a cloud account, even on the free tier, or any other cost incurring services.

## Optional Goals

While not all of these need to be implemented, the more of them that are completed, the better, but these are also expected to contain **production grade** quality, and will be evaluated under the same criteria explained above:

- Configure Kubernetes to authenticate to a private container repository;
- Create a script automating image building and deployment;
- Add a reverse proxy to route requests instead of exposing the main service;
- Write a few test scenarios, either for performance, functional or any other relevant kind of testing;
- Create a script to configure a local kubernetes cluster, deploy the application and run the test scenarios mentioned above;
- Configure the local kubernetes cluster to have 2+ worker nodes;
- Use [Helm](https://helm.sh/) on your application;
- Use [Terraform](https://www.terraform.io/) to configure the local environment of your application;
  - Use it to configure a remote environment on any cloud provider as well;  

## How to run this application

1. run `yarn install`
2. create a SQL database with `docker run -p 3306:3306 -e MYSQL_ROOT_PASSWORD=test -e MYSQL_DATABASE=test -e MYSQL_USER=test -e MYSQL_PASSWORD=test -d mariadb:5.5`
3. run `yarn typeorm migration:run`
4. open `http://localhost:3000/posts` and see an empty list
5. test with `curl`, `postman` or similar tools

## Deployment environments in the local cluster

This repo was iterated on in stages, and the local k3d cluster (`k3d-posts-cluster`) currently
has two namespaces running the same workload from two different stages. They are **not** meant
to coexist in a real setup — this is just how the local dev cluster ended up after building the
project incrementally:

| Namespace | How it's deployed | Manifests | Status |
| --- | --- | --- | --- |
| `posts-api` | manual `kubectl apply -f k8s/` | [k8s/](k8s/) raw manifests | Legacy — first pass (plain Deployment, no Helm, no Rollouts). Kept around from that stage, superseded by the rows below. |
| `posts-api-gitops` | ArgoCD, auto-synced from this repo's `main` | [charts/posts-api](charts/posts-api) Helm chart, applied via [gitops/application.yaml](gitops/application.yaml) | **Canonical.** Deploys an Argo Rollouts `Rollout` (canary) instead of a `Deployment`; ArgoCD prunes/self-heals any drift from what's committed. |

`posts-api-gitops` is the environment that reflects the current state of this repository (source
of truth = git, per the comment in `gitops/application.yaml`). The plain `posts-api` namespace
from the raw-manifests stage is left running only as a leftover from earlier local testing; delete
it with `kubectl delete namespace posts-api` once it's no longer needed for comparison.

## Infrastructure as code (Terraform)

[terraform/](terraform/) provisions the local k3d cluster, Argo CD, Argo Rollouts, and the
posts-api bootstrap from nothing — see [terraform/local](terraform/local/README.md) to run it.
[terraform/aws](terraform/aws/README.md) is a not-applied stub for the optional "remote
environment" goal.

## CI/CD

[.github/workflows/build-and-deploy.yml](.github/workflows/build-and-deploy.yml) builds and lints
on every push/PR; on `main` it also builds/pushes the image (tagged with the immutable commit SHA)
and commits that tag into `charts/posts-api/values.yaml`, which is what actually triggers Argo CD's
canary Rollout — CI never talks to the cluster directly.
