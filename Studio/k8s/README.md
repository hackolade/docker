# Kubernetes examples for `hackolade/hck-cli`

## Writable paths — `/data` and `/tmp` (recommended)

Runtime writes are steered to **`/data`** (PVC) and **`/tmp`** (memory `emptyDir`). **Use these consolidated mounts** — they match Compose examples and are required with `readOnlyRootFilesystem`.

| Mount | Backing | Holds |
| --- | --- | --- |
| `/data` | PVC | License state (`/data/app`), models, output, logs |
| `/tmp` | memory `emptyDir` | Scratch, sockets, caches |

Legacy `/home/hackolade/…` bind mounts from older Docker setups are not used here; prefer `/data` subpaths instead.

Same rule as [`compose.yml`](../compose.yml) and [`compose.hardened.yml`](../compose.hardened.yml). These manifests add the **hardened profile**: read-only root filesystem, non-root, dropped capabilities (Kubernetes **Restricted** Pod Security Standard).

Pin the image tag in each manifest. Append `-hardened` for the Docker Hardened Image (Debian) base — same Jobs. Ubuntu vs `-hardened`, preflight, and arbitrary UID: [image-variants.md](../doc/image-variants.md).

## Manifests

| File | Purpose |
| --- | --- |
| [`hck-cli-job.yaml`](./hck-cli-job.yaml) | Smoke test — runs `version` (`runAsUser: 1000`, `runAsGroup: 1001`, `fsGroup: 0`) |
| [`hck-cli-job-openshift.yaml`](./hck-cli-job-openshift.yaml) | OpenShift `restricted-v2`: omit `runAsUser` (SCC assigns an arbitrary UID), `runAsGroup: 0`, `fsGroup: 0` |
| [`hck-cli-gendoc-job.yaml`](./hck-cli-gendoc-job.yaml) | Example `genDoc` using a model on the PVC |

OpenShift injects a **random UID** in **group 0**. The image owns `/data` as `1000:0` mode `2775` so that UID can write; `nss-wrapper` supplies a passwd entry. Do not set `runAsUser: <uid>` with `runAsGroup: 1001` (or a random primary GID) without group 0 — `/data` will fail the writable-mount preflight. Full contract: [arbitrary UID](../doc/image-variants.md#arbitrary-uid).

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
- [Image variants, preflight, arbitrary UID](../doc/image-variants.md)
- [License validation](../doc/license-validation.md)
- [Custom TLS certificates](../doc/custom-certificates.md)
