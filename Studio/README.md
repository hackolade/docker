# Running Hackolade Studio CLI in Docker

![Docker Image Version (latest by date)](https://img.shields.io/docker/v/hackolade/hck-cli)

Run the **Hackolade Studio CLI** in Docker — typically in CI/CD pipelines.

⚠ **Not supported:** running the Hackolade GUI in a container.

Requires [Docker](https://www.docker.com/get-started).

## Documentation

| Guide | Description |
| --- | --- |
| **[getting-started-hck-cli.md](./doc/getting-started-hck-cli.md)** | Start here — `/data` + `/tmp` layout, profiles, quick start |
| **[example-offline-metadata-pipeline.md](./doc/example-offline-metadata-pipeline.md)** | **Full worked example** — image upgrade, offline license, `version` / `showLicense` / `listLogs` / `showLogs`, revEng → compMod → forweng → genDoc |
| **[docker-cli-howto.md](./doc/docker-cli-howto.md)** | `docker run` templates (local and hardened) |
| **[license-validation.md](./doc/license-validation.md)** | Floating license — online and offline |
| **[k8s/README.md](./k8s/README.md)** | Kubernetes Jobs (Restricted profile) |
| **[custom-certificates.md](./doc/custom-certificates.md)** | Trust private CAs |
| **[getting-started.md](./doc/getting-started.md)** | Legacy — custom-built `hackolade/studio` images |

```bash
docker compose -f compose.hardened.yml run --rm hck-cli
```

Always use **`run --rm`** for one-off CLI jobs — without it, stopped `…-run-…` containers pile up and Compose warns about orphans.

## Compose & manifests

| File | Profile |
| --- | --- |
| [compose.yml](./compose.yml) | Local — `/data` + `/tmp`, writable rootfs |
| [compose.hardened.yml](./compose.hardened.yml) | **Hardened** (CI / production) — read-only rootfs, `cap_drop: ALL` |
| [k8s/](./k8s/) | Kubernetes — same mounts + Restricted Pod Security Standard |

## Custom builds (legacy)

Build your own image when you need a custom plugin set: [build.md](./doc/build.md), [Dockerfile](./Dockerfile), [docker-compose.yml](./docker-compose.yml).

Windows batch helpers: [docker-help.bat](./docker-help.bat), [docker-validateKey.bat](./docker-validateKey.bat), [docker-genDoc.bat](./docker-genDoc.bat).

## Licensing

Docker CLI requires a **floating** license with an available seat. Workstation licenses do not work in containers. See [license-validation.md](./doc/license-validation.md). Contact support@hackolade.com to purchase.
