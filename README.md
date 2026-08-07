# Running Hackolade CLI in Docker

This repository provides **ready-to-use examples** for the pre-built [`hackolade/hck-cli`](https://hub.docker.com/r/hackolade/hck-cli/tags) image: Hackolade Studio CLI, all target plugins, and a hardened runtime layout (`/data` + `/tmp`) — no build step required.

![Docker Image Version (latest by date)](https://img.shields.io/docker/v/hackolade/hck-cli)

**Start here:** [Getting started with hackolade/hck-cli](./Studio/doc/getting-started-hck-cli.md)

The [`Studio/`](./Studio) folder includes:

- [`compose.yml`](./Studio/compose.yml) — simple local Compose example
- [`compose.hardened.yml`](./Studio/compose.hardened.yml) — read-only rootfs, dropped capabilities (Kubernetes Restricted parity)
- [`k8s/`](./Studio/k8s/) — Job manifests with PVC at `/data` and memory `emptyDir` at `/tmp`

## Custom-built images (legacy runtime)

If you need a custom plugin set or a bespoke image, you can still build on the [`hackolade/studio`](https://hub.docker.com/r/hackolade/studio/tags) runtime base image. That path requires a build step and uses the legacy `/home/hackolade/Documents/*` layout.

See [Building your own image](./Studio/doc/getting-started.md) and [build.md](./Studio/doc/build.md).
