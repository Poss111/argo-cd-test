# Argo CD Environment Promotion Example

This repository is a documented GitOps reference for deploying the same workload
to `dev`, `test`, and `prod` with Argo CD while keeping environment-specific
Kubernetes objects separate and reviewable.

The example uses Kustomize because it is simple, built into Argo CD, and makes
the difference between shared application intent and environment policy easy to
see in Git.

## Repository Layout

```text
.
├── apps/
│   └── sample-api/
│       ├── base/                 # Shared workload shape
│       ├── values/
│       │   └── common.yaml        # Shared sample Helm values
│       └── overlays/
│           ├── dev/              # Dev-only objects and values
│           ├── test/             # Test-only objects and values
│           └── prod/             # Prod-only objects and values
├── argocd/
│   ├── applications/             # Argo CD Application definitions
│   ├── projects/                 # AppProject guardrails
│   └── kustomization.yaml        # Bootstrap entry point
├── helm-example/                 # Separate Helm chart example
│   ├── argocd/                   # Helm-based Argo CD Applications
│   └── sample-api/               # Renderable Helm chart
└── docs/
    └── promotion.md              # Promotion workflow and object separation
```

## What This Demonstrates

1. Deploying one application to `dev`, `test`, and `prod`.
2. Separating different Kubernetes objects per environment.
3. Documenting Argo CD principles for a best-practice GitOps repository.

## Argo CD Principles Followed

### Git Is The Source Of Truth

All desired state lives in this repository. Argo CD should reconcile clusters
from Git rather than from manual `kubectl apply` commands or dashboard edits.

### Immutable Promotion

Environment promotion should be a Git change. In a real system, promote by
updating the image tag, chart version, or commit reference in a pull request.
The sample overlays intentionally keep environment differences visible so
reviewers can tell whether a promotion changes only the release version or also
changes runtime policy.

### Clear Separation Of Shared And Environment-Specific State

The base contains the objects every environment needs:

- `Deployment`
- `Service`
- shared labels and selectors

Each overlay includes only the objects that belong to that environment. For
example, `prod` includes `HorizontalPodAutoscaler`, `PodDisruptionBudget`, and
`NetworkPolicy`, while `dev` includes a developer-focused `ConfigMap`.

The repository also includes sample values files for Helm-style deployments:

- `apps/sample-api/values/common.yaml`
- `apps/sample-api/overlays/dev/values.yaml`
- `apps/sample-api/overlays/test/values.yaml`
- `apps/sample-api/overlays/prod/values.yaml`

Use the common values file for stable defaults and environment values files for
only the configuration that differs by environment.

### AppProject Guardrails

The `sample-platform` AppProject scopes the applications to expected
namespaces, resource kinds, and destination clusters. This is where teams should
encode safety boundaries such as permitted namespaces, allowed cluster-scoped
resources, and destination restrictions.

### One Application Per Environment

Each environment has its own Argo CD `Application`. This keeps sync history,
health, RBAC, rollback, and drift detection separate per environment.

### Prefer Declarative Sync Policy

The example enables automated sync with prune and self-heal. This keeps the
cluster converged to Git and removes objects that are deleted from the
environment overlay.

### Keep Secrets Out Of Plain Git

This repository does not include Kubernetes `Secret` manifests. In production,
use a GitOps-friendly secret strategy such as External Secrets Operator, Sealed
Secrets, SOPS, or a cloud secret manager integration.

## How To Bootstrap

Replace `https://github.com/your-org/argo-cd-test.git` in the Argo CD
Application manifests with the real repository URL.

Then apply the Argo CD bootstrap layer:

```sh
kubectl apply -k argocd
```

Argo CD will create three applications:

- `sample-api-dev`
- `sample-api-test`
- `sample-api-prod`

Each application points at a different overlay under
`apps/sample-api/overlays`.

## How Environment Object Separation Works

The shared base is intentionally small:

```text
apps/sample-api/base
```

Environment overlays add or patch what differs:

- `dev` uses a single replica, lower resource requests, and a dev-only
  `ConfigMap`.
- `test` uses two replicas, test resource sizing, and an `Ingress` for
  integration validation.
- `prod` uses higher replicas, production resource sizing, `Ingress`,
  `HorizontalPodAutoscaler`, `PodDisruptionBudget`, and `NetworkPolicy`.

That gives reviewers a direct answer to: "What is different in prod?"

```sh
kubectl kustomize apps/sample-api/overlays/dev
kubectl kustomize apps/sample-api/overlays/test
kubectl kustomize apps/sample-api/overlays/prod
```

## Sample Values Files

The values files demonstrate the same separation pattern for Helm-based
applications. A typical Argo CD Helm source would include the common file first
and the environment file second, so environment configuration overrides shared
defaults:

```yaml
source:
  repoURL: https://github.com/your-org/argo-cd-test.git
  targetRevision: HEAD
  path: charts/sample-api
  helm:
    valueFiles:
      - ../../apps/sample-api/values/common.yaml
      - ../../apps/sample-api/overlays/prod/values.yaml
```

Use values files for chart inputs such as replica count, resources, hostnames,
feature flags, and autoscaling settings. Use Kustomize overlays or standalone
manifests for objects that are not part of a Helm chart or that need clear
environment ownership.

For a complete Helm version of this pattern, see `helm-example`. That folder has
a renderable chart and separate Argo CD Applications that pass common values plus
one environment-specific values file.

## Suggested Promotion Flow

1. Merge application changes into `dev`.
2. Let Argo CD sync `sample-api-dev`.
3. Validate the application in the dev namespace.
4. Promote to `test` with a pull request that changes only the test overlay.
5. Promote to `prod` with a separate reviewed pull request.

For a larger organization, use branch protection, CODEOWNERS, required checks,
and Argo CD RBAC so production changes require explicit approval.

## Validation Commands

Render each overlay locally before opening a pull request:

```sh
kubectl kustomize apps/sample-api/overlays/dev
kubectl kustomize apps/sample-api/overlays/test
kubectl kustomize apps/sample-api/overlays/prod
```

Validate the Argo CD bootstrap layer:

```sh
kubectl kustomize argocd
```
