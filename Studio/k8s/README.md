# Kubernetes examples for `hackolade/hck-cli`

Job manifests that match [`compose.hardened.yml`](../compose.hardened.yml): read-only root filesystem, non-root user, dropped capabilities, **PVC at `/data`**, and **memory `emptyDir` at `/tmp`**.

Pin the image tag in each manifest (default: `hackolade/hck-cli:8.12.7`).

## Manifests

| File | Purpose |
| --- | --- |
| [`hck-cli-job.yaml`](./hck-cli-job.yaml) | Smoke test — runs `version` |
| [`hck-cli-job-openshift.yaml`](./hck-cli-job-openshift.yaml) | Same, for OpenShift `restricted-v2` (arbitrary UID) |
| [`hck-cli-gendoc-job.yaml`](./hck-cli-gendoc-job.yaml) | Example `genDoc` using a model on the PVC |

## Quick test

```bash
kubectl apply -f hck-cli-job.yaml
kubectl wait --for=condition=complete job/hck-cli-version --timeout=120s
kubectl logs job/hck-cli-version
```

## Before you run a real command

1. **License** — validate once and persist state on the PVC (easiest: run [`compose.yml`](../compose.yml) locally, then reuse the volume data, or run a one-off validation Job).
2. **Models** — for `genDoc`, place a `.hck.json` file under `/data/models/` on the PVC.
3. **Storage class** — edit the PVC in the manifest if your cluster needs a specific `storageClassName`.

## Writable mounts

| Mount | Backing | Holds |
| --- | --- | --- |
| `/data` | PVC | License state (`/data/app`), models, output, logs |
| `/tmp` | memory `emptyDir` | Sockets, caches, scratch (required when `readOnlyRootFilesystem: true`) |

## See also

- [Getting started with hck-cli](../doc/getting-started-hck-cli.md)
- [License validation](../doc/license-validation.md)
- [Custom TLS certificates](../doc/custom-certificates.md)
