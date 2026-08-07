# Running Hackolade CLI in Docker

This repository provides **ready-to-use examples** for the pre-built [`hackolade/hck-cli`](https://hub.docker.com/r/hackolade/hck-cli/tags) image: Hackolade Studio CLI, all target plugins, no build step.

![Docker Image Version (latest by date)](https://img.shields.io/docker/v/hackolade/hck-cli)

All examples and compose files live under **[`Studio/`](./Studio)**.

## Writable paths — `/data` and `/tmp` (recommended)

The **`hackolade/hck-cli`** image steers **runtime writes** to **`/data`** and **`/tmp`** via XDG environment variables:

| Path | Mount | Purpose |
| --- | --- | --- |
| **`/data`** | Volume or PVC | License, logs, models, output, settings — everything that must persist |
| **`/tmp`** | tmpfs / memory `emptyDir` | Sockets, caches, scratch — everything ephemeral |

**Use these consolidated mounts** in new deployments (all examples in this repo do). Older layouts under `/home/hackolade/.config` and `/home/hackolade/Documents/*` may still work on a writable root filesystem, but `/data` + `/tmp` is simpler and required for read-only rootfs / Kubernetes.

Details: [Getting started — writable paths](./Studio/doc/getting-started-hck-cli.md#writable-paths-data-and-tmp-recommended).

## Documentation

| Guide | When to use it |
| --- | --- |
| **[Getting started](./Studio/doc/getting-started-hck-cli.md)** | First run — `/data` + `/tmp` mounts, deployment profiles, quick commands |
| **[Offline pipeline example](./Studio/doc/example-offline-metadata-pipeline.md)** | **Full CI walkthrough** — image upgrade, offline license, revEng → compMod → DDL → docs |
| **[Docker CLI how-to](./Studio/doc/docker-cli-howto.md)** | `docker run` without Compose (local and hardened) |
| **[License validation](./Studio/doc/license-validation.md)** | Online / offline floating license |
| **[Kubernetes](./Studio/k8s/README.md)** | Restricted Pod Security Standard Jobs |
| **[Custom TLS certificates](./Studio/doc/custom-certificates.md)** | Private CAs in hardened / K8s setups |

```bash
cd Studio
docker compose -f compose.hardened.yml run --rm hck-cli
```

## Legacy custom builds

Need a custom plugin set? Build on [`hackolade/studio`](https://hub.docker.com/r/hackolade/studio/tags) — see [getting-started.md](./Studio/doc/getting-started.md).
