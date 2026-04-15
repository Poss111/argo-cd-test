# Promotion And Environment Separation

This repository models environments as separate Kustomize overlays. The base
defines the common application contract, while each overlay owns the deployment
settings and supporting objects that are appropriate for that environment.

## Promotion Model

The recommended promotion path is:

```text
dev -> test -> prod
```

Promotion should happen through pull requests. The pull request should make it
obvious whether the change is a release promotion, an environment policy change,
or both.

## Object Separation

Use the base for objects that every environment must have:

- workload controllers
- services
- common labels
- stable selectors

Use overlays for objects that vary by environment:

- replica counts
- resource requests and limits
- ingress hostnames
- autoscaling policies
- disruption budgets
- network policy
- environment-specific config

Use values files for chart inputs that vary by environment:

- image tags or chart versions
- replica counts
- resource sizing
- hostnames
- feature flags
- autoscaling settings
- external secret references

Keep shared defaults in `apps/sample-api/values/common.yaml`. Keep the
environment-specific overrides next to the environment overlay at
`apps/sample-api/overlays/<env>/values.yaml`.

When a Helm chart is used, list values files from broadest to most specific:

```text
common.yaml -> dev values.yaml
common.yaml -> test values.yaml
common.yaml -> prod values.yaml
```

## Why This Matters

Separating objects by environment prevents accidental production behavior from
leaking into dev and prevents dev conveniences from leaking into prod. It also
makes reviews sharper because every environment-specific object has a clear home.

## Scaling This Pattern

For more applications, repeat the same shape under `apps/<app-name>`.

For many applications, consider an app-of-apps or ApplicationSet bootstrap, but
keep each application environment pointed at an explicit overlay. The important
principle is that Argo CD syncs a clear desired state path for each environment.
