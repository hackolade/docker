# Running Hackolade CLI in Docker

This repository provides **ready-to-use examples** for the pre-built [`hackolade/hck-cli`](https://hub.docker.com/r/hackolade/hck-cli/tags) image: Hackolade Studio CLI, all target plugins, no build step.

![Docker Image Version (latest by date)](https://img.shields.io/docker/v/hackolade/hck-cli)

**Start here:** [Getting started with hackolade/hck-cli](./Studio/doc/getting-started-hck-cli.md)

## Runtime model

All examples use the **same two write paths** (whether or not the root filesystem is read-only):

- **`/data`** — persistent volume or PVC (license, models, output, logs)
- **`/tmp`** — tmpfs / memory emptyDir (ephemeral scratch)

## Examples in [`Studio/`](./Studio)

| File | Profile |
| --- | --- |
| [`compose.yml`](./Studio/compose.yml) | Local — consolidated `/data` + `/tmp` |
| [`compose.hardened.yml`](./Studio/compose.hardened.yml) | **Hardened** — same mounts + read-only rootfs, dropped caps (CI / production) |
| [`k8s/`](./Studio/k8s/) | **Kubernetes** — same mounts + Restricted Pod Security Standard |

## Custom-built images (legacy)

Build on [`hackolade/studio`](https://hub.docker.com/r/hackolade/studio/tags) if you need a custom plugin set. That path uses the legacy `/home/hackolade/Documents/*` layout — see [getting-started.md](./Studio/doc/getting-started.md).
