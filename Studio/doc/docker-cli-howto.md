# Docker CLI how-to (`docker run`)

Use this guide when you prefer **`docker run`** over Compose.

> **Recommended mounts:** **`/data`** (volume) and **`/tmp`** (tmpfs). The image steers runtime writes there. Legacy `/home/hackolade/…` paths may still work on a writable rootfs, but prefer the consolidated layout — see [getting-started-hck-cli.md](./getting-started-hck-cli.md#writable-paths-data-and-tmp-recommended).

Every example below includes both mounts.

For a full end-to-end pipeline (offline license, revEng, compMod, forweng, genDoc), see **[example-offline-metadata-pipeline.md](./example-offline-metadata-pipeline.md)**.

Pin the image tag (example: `hackolade/hck-cli:8.12.8` or `hackolade/hck-cli:8.12.8-hardened`). `latest` is not published. Ubuntu vs Docker Hardened Image, startup preflight, and arbitrary UID: **[image-variants.md](./image-variants.md)**.

## Local profile

Writable root filesystem — minimal flags. Pass **`version`** explicitly with `docker run` (Compose sets it as the default service command):

```bash
docker volume create hackolade-studio-data

docker run --rm \
  -v hackolade-studio-data:/data \
  -v "${PWD}/models:/data/models" \
  --tmpfs /tmp:rw,size=1g,mode=1777 \
  hackolade/hck-cli:8.12.8 version
```

Expect `Hackolade version: …` and an `Installed plugins (N):` list (name, version, commit, build date per plugin).

## Hardened profile (CI / production)

Read-only root filesystem, non-root, dropped capabilities — mirrors [`compose.hardened.yml`](../compose.hardened.yml). `group_add` / `--group-add 0` keeps **group 0** so an overridden UID can still write `/data` (OpenShift `restricted-v2` does the same). Either image tag works:

```bash
docker run --rm \
  --init \
  --read-only \
  --user 1000:1001 \
  --group-add 0 \
  --cap-drop ALL \
  --security-opt no-new-privileges:true \
  -v hackolade-studio-data:/data \
  -v "${PWD}/models:/data/models" \
  --tmpfs /tmp:rw,size=1g,mode=1777 \
  hackolade/hck-cli:8.12.8 version
```

OpenShift-style arbitrary UID (no passwd entry, group 0):

```bash
docker run --rm \
  --init --read-only --user 31337:0 --group-add 0 \
  --cap-drop ALL --security-opt no-new-privileges:true \
  -v hackolade-studio-data:/data \
  --tmpfs /tmp:rw,size=1g,mode=1777 \
  hackolade/hck-cli:8.12.8-hardened version
```

## Diagnostics

Wrapper commands — no full Studio session:

```bash
docker run --rm ... hackolade/hck-cli:8.12.8 showLicense
docker run --rm ... hackolade/hck-cli:8.12.8 showLicense --json
docker run --rm ... hackolade/hck-cli:8.12.8 listLogs
docker run --rm ... hackolade/hck-cli:8.12.8 showLogs <runId> --tail 50 --logfile re
```

Replace `...` with the same volume and security flags as above. Details: [getting-started-hck-cli.md](./getting-started-hck-cli.md#inspecting-the-image-license-and-logs).

## Run a CLI command

```bash
docker run --rm \
  --init --read-only --user 1000:1001 --group-add 0 --cap-drop ALL \
  --security-opt no-new-privileges:true \
  -v hackolade-studio-data:/data \
  -v "${PWD}/models:/data/models" \
  --tmpfs /tmp:rw,size=1g,mode=1777 \
  hackolade/hck-cli:8.12.8 genDoc \
  --format=HTML \
  --model /data/models/my-model.hck.json \
  --doc /data/output/doc
```

## Copy artifacts from the volume

```bash
mkdir -p ./artifacts
docker run --rm --user root \
  -v hackolade-studio-data:/data:ro \
  -v "${PWD}/artifacts:/host" \
  --entrypoint cp \
  hackolade/hck-cli:8.12.8 -r /data/output/. /host/
```

## See also

- [Getting started with hck-cli](./getting-started-hck-cli.md)
- [Image variants, preflight, arbitrary UID](./image-variants.md)
- [Example: offline metadata pipeline](./example-offline-metadata-pipeline.md)
- [License validation](./license-validation.md)
