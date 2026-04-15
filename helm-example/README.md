# Helm Argo CD Example

This folder shows the same `dev`, `test`, and `prod` deployment pattern using a
Helm chart instead of Kustomize overlays.

## Layout

```text
helm-example/
├── argocd/
│   ├── applications/
│   └── kustomization.yaml
└── sample-api/
    ├── Chart.yaml
    ├── values.yaml
    ├── values/
    │   ├── common.yaml
    │   ├── dev.yaml
    │   ├── test.yaml
    │   └── prod.yaml
    └── templates/
```

## How Helm Uses Shared Objects

With Helm, the chart templates are the reusable base. Argo CD points at the
chart path and passes values files in order:

```text
values/common.yaml -> values/dev.yaml
values/common.yaml -> values/test.yaml
values/common.yaml -> values/prod.yaml
```

The chart always renders shared objects such as `Deployment`, `Service`, and
`ConfigMap`. Environment-specific objects are controlled by values:

- `dev` disables ingress, autoscaling, disruption budget, and network policy.
- `test` enables ingress for integration validation.
- `prod` enables ingress, autoscaling, disruption budget, and network policy.

## Render Locally

```sh
helm template sample-api-dev ./helm-example/sample-api \
  --namespace sample-api-dev \
  -f ./helm-example/sample-api/values/common.yaml \
  -f ./helm-example/sample-api/values/dev.yaml

helm template sample-api-test ./helm-example/sample-api \
  --namespace sample-api-test \
  -f ./helm-example/sample-api/values/common.yaml \
  -f ./helm-example/sample-api/values/test.yaml

helm template sample-api-prod ./helm-example/sample-api \
  --namespace sample-api-prod \
  -f ./helm-example/sample-api/values/common.yaml \
  -f ./helm-example/sample-api/values/prod.yaml
```

## Bootstrap The Helm Applications

Replace the placeholder repository URL in `helm-example/argocd/applications`
with the real Git repository URL, then apply:

```sh
kubectl apply -k helm-example/argocd
```

