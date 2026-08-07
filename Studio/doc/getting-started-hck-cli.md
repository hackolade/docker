# Getting started with `hackolade/hck-cli`

Ready-to-use Docker image: Hackolade Studio CLI, all target plugins, no build step.

![Docker Image Version (latest by date)](https://img.shields.io/docker/v/hackolade/hck-cli)

## Before you start

- **Floating license only** — workstation licenses do not work in Docker.
- **Pin a version tag** — `latest` is not published. Example: `hackolade/hck-cli:8.12.7`. Weekly plugin refreshes may appear as `8.12.7-YYYY-MM-DD` on the [current release only](https://hub.docker.com/r/hackolade/hck-cli/tags).
- **Re-validate when the image tag changes** — license state is tied to the image UUID.
- **Two writable mounts** — persistent `/data` plus writable `/tmp` (tmpfs in hardened setups).

Need a custom plugin set or your own Dockerfile? See [getting-started.md](./getting-started.md) (build on `hackolade/studio`).

## Quick start (Docker Compose)

1. Copy [`compose.yml`](../compose.yml) and create a models folder:

```bash
cp compose.yml .
mkdir -p ./models
```

2. Pull and check the image:

```bash
docker compose pull
docker compose run --rm hck-cli version
```

3. Validate your license (online example — adjust secret paths in `compose.yml`):

```bash
echo "YOUR-FLOATING-LICENSE-KEY" > ~/license-key.txt
chmod 600 ~/license-key.txt
docker compose run --rm validateKeyOnline
```

4. Run a command:

```bash
docker compose run --rm hck-cli genDoc \
  --format=HTML \
  --model /data/models/my-model.hck.json \
  --doc /data/output/doc
```

Offline validation and license details: [license-validation.md](./license-validation.md).

## Compose examples

| File | Use when |
| --- | --- |
| [`compose.yml`](../compose.yml) | Local use — minimal setup |
| [`compose.hardened.yml`](../compose.hardened.yml) | Production / CI — read-only rootfs, `cap_drop: ALL`, `/tmp` tmpfs |

```bash
docker compose -f compose.hardened.yml run --rm hck-cli version
```

## Storage layout

Runtime writes go to **only two places**:

| Mount | Purpose |
| --- | --- |
| `/data` | License state (`/data/app`), models, output, logs, settings |
| `/tmp` | Sockets, caches, scratch (use tmpfs when `read_only: true`) |

The container runs as UID **1000**, GID **1001** by default.

## Image tags

| Tag | Meaning |
| --- | --- |
| `hackolade/hck-cli:8.12.7` | Current Hackolade Studio release |
| `hackolade/hck-cli:8.12.7-2026-08-07` | Example intermediate tag (plugin updates on the current release) |

Update the `image:` line in your compose file, then `docker compose pull`.

## Production and Kubernetes

- **Docker Compose (restricted profile):** [`compose.hardened.yml`](../compose.hardened.yml)
- **Kubernetes Jobs:** [`k8s/`](../k8s/) — see [`k8s/README.md`](../k8s/README.md)
- **Private CAs:** [custom-certificates.md](./custom-certificates.md)

## Docker CLI (without Compose)

```bash
docker volume create hackolade-studio-data

docker run --rm \
  -v hackolade-studio-data:/data \
  -v "${PWD}/models:/data/models" \
  hackolade/hck-cli:8.12.7 version
```

For read-only rootfs, add `--read-only`, `--tmpfs /tmp:rw,size=1g,mode=1777`, `--user 1000:1001`, and `--cap-drop=ALL` — or use `compose.hardened.yml` as the reference.

## Troubleshooting

| Problem | Check |
| --- | --- |
| Permission denied on `./models` | `chown -R 1000:1001 ./models` |
| Fails under `read_only: true` | Mount writable `/tmp` (tmpfs) |
| License validation fails | Same image tag for UUID + validation; floating seat available |
| Secret not found | Paths in `compose.yml` `secrets:` match files on disk |

## See also

- [License validation](./license-validation.md)
- [Custom TLS certificates](./custom-certificates.md)
- [Build your own image](./getting-started.md)
- [Hackolade CLI command reference](https://hackolade.com/help/CommandLineInterface.html)
