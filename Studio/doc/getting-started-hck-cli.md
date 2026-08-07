# Getting started with `hackolade/hck-cli`

Ready-to-use Docker image: Hackolade Studio CLI, all target plugins, no build step.

![Docker Image Version (latest by date)](https://img.shields.io/docker/v/hackolade/hck-cli)

## Runtime model (all deployments)

Every `hackolade/hck-cli` container uses the **same consolidated write layout** — whether you enable a read-only root filesystem or not. Runtime state is not scattered under `/home/hackolade/...` anymore.

**Exactly two writable locations:**

| Mount | Backing | Holds |
| --- | --- | --- |
| **`/data`** | Named volume or PVC | License state (`/data/app`), models, output, logs, settings |
| **`/tmp`** | tmpfs or memory `emptyDir` | Sockets, caches, scratch (ephemeral) |

Everything persistent lives under **`/data`**. Everything transient goes to **`/tmp`**.

This is the same layout in [`compose.yml`](../compose.yml), [`compose.hardened.yml`](../compose.hardened.yml), and the [`k8s/`](../k8s/) Job manifests — only the **security profile** changes.

## Deployment profiles

| Profile | Compose / manifest | Read-only rootfs | Extra hardening |
| --- | --- | --- | --- |
| **Local** | [`compose.yml`](../compose.yml) | No | Same `/data` + `/tmp` mounts |
| **Hardened** (recommended for CI / production) | [`compose.hardened.yml`](../compose.hardened.yml) | Yes | `cap_drop: ALL`, non-root, no privilege escalation |
| **Kubernetes** | [`k8s/hck-cli-job.yaml`](../k8s/hck-cli-job.yaml) | Yes | Same as hardened Compose (Restricted Pod Security Standard) |

```bash
# Hardened smoke test (recommended baseline for pipelines)
docker compose -f compose.hardened.yml run --rm hck-cli version
```

OpenShift arbitrary UID: [`compose.hardened.yml`](../compose.hardened.yml) (`hck-cli-arbitrary-uid`) or [`k8s/hck-cli-job-openshift.yaml`](../k8s/hck-cli-job-openshift.yaml).

## Before you start

- **Floating license only** — workstation licenses do not work in Docker.
- **Pin a version tag** — `latest` is not published. Example: `hackolade/hck-cli:8.12.7`. Weekly plugin refreshes may appear as `8.12.7-YYYY-MM-DD` on the [current release only](https://hub.docker.com/r/hackolade/hck-cli/tags).
- **Re-validate when the image tag changes** — license state is tied to the image UUID.
- **Mount `/data` and `/tmp` on every run** — required when `read_only: true`; use the same layout even when the root filesystem is writable.

Need a custom plugin set or your own Dockerfile? See [getting-started.md](./getting-started.md) (legacy `hackolade/studio` build path).

## Quick start

1. Copy a compose file and create a models folder:

```bash
cp compose.hardened.yml compose.local.yml   # or compose.yml for a minimal local run
mkdir -p ./models
```

2. Pull and check the image:

```bash
docker compose -f compose.local.yml pull
docker compose -f compose.local.yml run --rm hck-cli version
```

3. Validate your license (online — adjust secret paths in the compose file):

```bash
echo "YOUR-FLOATING-LICENSE-KEY" > ~/license-key.txt
chmod 600 ~/license-key.txt
docker compose -f compose.local.yml run --rm validateKeyOnline
```

4. Run a command:

```bash
docker compose -f compose.local.yml run --rm hck-cli genDoc \
  --format=HTML \
  --model /data/models/my-model.hck.json \
  --doc /data/output/doc
```

Offline validation: [license-validation.md](./license-validation.md).

## Image tags

| Tag | Meaning |
| --- | --- |
| `hackolade/hck-cli:8.12.7` | Current Hackolade Studio release |
| `hackolade/hck-cli:8.12.7-2026-08-07` | Example intermediate tag (plugin updates on the current release) |

Update the `image:` line in your compose file, then `docker compose pull`.

## Docker CLI (without Compose)

Same two-mount layout:

```bash
docker volume create hackolade-studio-data

docker run --rm \
  -v hackolade-studio-data:/data \
  -v "${PWD}/models:/data/models" \
  --tmpfs /tmp:rw,size=1g,mode=1777 \
  hackolade/hck-cli:8.12.7 version
```

Hardened flags (`--read-only`, `--user 1000:1001`, `--cap-drop=ALL`): see [`compose.hardened.yml`](../compose.hardened.yml).

## Troubleshooting

| Problem | Check |
| --- | --- |
| Permission denied on `./models` | `chown -R 1000:1001 ./models` |
| Fails with read-only rootfs | Writable `/tmp` tmpfs is mounted |
| License validation fails | Same image tag for UUID + validation; floating seat available |
| Secret not found | Paths in compose `secrets:` match files on disk |

## See also

- [License validation](./license-validation.md)
- [Custom TLS certificates](./custom-certificates.md) (read-only PEM mounts — works with hardened / K8s)
- [Kubernetes examples](../k8s/README.md)
- [Build your own image](./getting-started.md)
- [Hackolade CLI command reference](https://hackolade.com/help/CommandLineInterface.html)
