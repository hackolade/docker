# Kubernetes examples for `hackolade/hck-cli`

## Writable paths — `/data` and `/tmp` only

The image writes runtime data **only** to **`/data`** (PVC) and **`/tmp`** (memory `emptyDir`). **No other path** receives writes — not `/home/hackolade/...`, not anywhere on the read-only root filesystem.

| Mount | Backing | Holds |
| --- | --- | --- |
| `/data` | PVC | License state (`/data/app`), models, output, logs |
| `/tmp` | memory `emptyDir` | Scratch, sockets, caches (required with `readOnlyRootFilesystem`) |

Same rule as [`compose.yml`](../compose.yml) and [`compose.hardened.yml`](../compose.hardened.yml). These manifests add the **hardened profile**: read-only root filesystem, non-root, dropped capabilities (Kubernetes **Restricted** Pod Security Standard).

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

1. **License** — validate once and persist state on the PVC (easiest: run Compose locally, then reuse volume data).
2. **Models** — for `genDoc`, place a `.hck.json` under `/data/models/` on the PVC.
3. **Storage class** — edit the PVC if your cluster needs a specific `storageClassName`.

## See also

- [Getting started with hck-cli](../doc/getting-started-hck-cli.md) — runtime model and deployment profiles
- [License validation](../doc/license-validation.md)
- [Custom TLS certificates](../doc/custom-certificates.md)
