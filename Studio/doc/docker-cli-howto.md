# Docker CLI how-to (`docker run`)

Use this guide when you prefer **`docker run`** over Compose. The same **`/data` + `/tmp`** write layout applies — see [getting-started-hck-cli.md](./getting-started-hck-cli.md).

For a full end-to-end pipeline (offline license, revEng, compMod, forweng, genDoc), see **[example-offline-metadata-pipeline.md](./example-offline-metadata-pipeline.md)**.

Pin the image tag (example: `hackolade/hck-cli:8.12.7`). `latest` is not published.

## Local profile

Writable root filesystem — minimal flags. Pass **`version`** explicitly with `docker run` (Compose sets it as the default service command):

```bash
docker volume create hackolade-studio-data

docker run --rm \
  -v hackolade-studio-data:/data \
  -v "${PWD}/models:/data/models" \
  --tmpfs /tmp:rw,size=1g,mode=1777 \
  hackolade/hck-cli:8.12.7 version
```

Expect `Hackolade version: …` and an `Installed plugins (N):` list (name, version, commit, build date per plugin).

## Hardened profile (CI / production)

Read-only root filesystem, non-root, dropped capabilities — mirrors [`compose.hardened.yml`](../compose.hardened.yml):

```bash
docker run --rm \
  --init \
  --read-only \
  --user 1000:1001 \
  --cap-drop ALL \
  --security-opt no-new-privileges:true \
  -v hackolade-studio-data:/data \
  -v "${PWD}/models:/data/models" \
  --tmpfs /tmp:rw,size=1g,mode=1777 \
  hackolade/hck-cli:8.12.7 version
```

## Diagnostics

Wrapper commands — no full Studio session:

```bash
docker run --rm ... hackolade/hck-cli:8.12.7 showLicense
docker run --rm ... hackolade/hck-cli:8.12.7 showLicense --json
docker run --rm ... hackolade/hck-cli:8.12.7 listLogs
docker run --rm ... hackolade/hck-cli:8.12.7 showLogs <runId> --tail 50 --logfile re
```

Replace `...` with the same volume and security flags as above. Details: [getting-started-hck-cli.md](./getting-started-hck-cli.md#inspecting-the-image-license-and-logs).

## Run a CLI command

```bash
docker run --rm \
  --init --read-only --user 1000:1001 --cap-drop ALL \
  --security-opt no-new-privileges:true \
  -v hackolade-studio-data:/data \
  -v "${PWD}/models:/data/models" \
  --tmpfs /tmp:rw,size=1g,mode=1777 \
  hackolade/hck-cli:8.12.7 genDoc \
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
  hackolade/hck-cli:8.12.7 -r /data/output/. /host/
```

## See also

- [Getting started with hck-cli](./getting-started-hck-cli.md)
- [Example: offline metadata pipeline](./example-offline-metadata-pipeline.md)
- [License validation](./license-validation.md)
