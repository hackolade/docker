# Getting started with `hackolade/hck-cli`

Ready-to-use Docker image: Hackolade Studio CLI, all target plugins, no build step.

![Docker Image Version (latest by date)](https://img.shields.io/docker/v/hackolade/hck-cli)

## Guides

| Guide | Use when |
| --- | --- |
| **This page** | First run, deployment profiles, troubleshooting |
| **[Image variants, preflight, arbitrary UID](./image-variants.md)** | Ubuntu vs `-hardened` (DHI) tags, startup checks, OpenShift/K8s UID |
| **[Offline pipeline example](./example-offline-metadata-pipeline.md)** | **Complete CI story** — new image tag, offline license, revEng → compMod → DDL → docs, plus `version`, `showLicense`, `listLogs`, `showLogs` |
| **[Docker CLI how-to](./docker-cli-howto.md)** | You prefer **`docker run`** instead of Compose |
| **[License validation](./license-validation.md)** | Online or offline floating license setup |
| **[Kubernetes](../k8s/README.md)** | Running on K8s / OpenShift |
| **[Custom TLS certificates](./custom-certificates.md)** | Private CAs with read-only PEM mounts |

## Writable paths — `/data` and `/tmp` (recommended)

> **Recommended:** mount **`/data`** and **`/tmp`** — the image steers **all runtime writes** there via XDG environment variables (`DATA_DIR`, `TMPDIR`, …).

| Path | What gets written there | Persists? |
| --- | --- | --- |
| **`/data`** | License/userData (`/data/app`), command logs (`/data/logs`), models, forward/reverse-engineering output, settings | Yes — use a named volume or PVC |
| **`/tmp`** | Unix sockets, plugin caches, Electron/Chromium scratch, XDG runtime dir | No — tmpfs or memory `emptyDir` |

**Legacy paths** (older examples and custom-built images) used mounts such as `/home/hackolade/.config/Hackolade`, `/home/hackolade/Documents/HackoladeLogs`, and `/home/hackolade/Documents/data`. Those bind mounts **can still work** on a writable root filesystem if you keep using them, but **prefer the consolidated `/data` + `/tmp` layout** — fewer volumes, same paths in Compose and Kubernetes, and required for read-only rootfs.

Put host folders **under `/data`** (e.g. `${PWD}/models:/data/models`). With **`read_only: true`**, only **`/data`** and **`/tmp`** are writable; legacy paths on the root filesystem will not receive new writes.

This is the same rule in [`compose.yml`](../compose.yml), [`compose.hardened.yml`](../compose.hardened.yml), and [`k8s/`](../k8s/) — only the **security profile** (read-only rootfs, caps, user) changes.

## Deployment profiles

| Profile | Compose / manifest | Read-only rootfs | Extra hardening |
| --- | --- | --- | --- |
| **Local** | [`compose.yml`](../compose.yml) | No | Same `/data` + `/tmp` mounts |
| **Hardened** (recommended for CI / production) | [`compose.hardened.yml`](../compose.hardened.yml) | Yes | `cap_drop: ALL`, non-root, no privilege escalation. Runtime profile — not the `-hardened` image tag |
| **Kubernetes** | [`k8s/hck-cli-job.yaml`](../k8s/hck-cli-job.yaml) | Yes | Same as hardened Compose (Restricted Pod Security Standard) |

```bash
# Hardened smoke test (recommended baseline for pipelines)
# `version` is the default command — explicit `version` arg is optional
docker compose -f compose.hardened.yml run --rm hck-cli
```

OpenShift arbitrary UID: [`compose.hardened.yml`](../compose.hardened.yml) (`hck-cli-arbitrary-uid`) or [`k8s/hck-cli-job-openshift.yaml`](../k8s/hck-cli-job-openshift.yaml). Details: [image-variants.md](./image-variants.md#arbitrary-uid).

`compose.hardened.yml` is the **runtime profile** (read-only rootfs). The **`-hardened` image tag** is a different OS base (Docker Hardened Debian). Either tag works with either compose file — [image-variants.md](./image-variants.md).

## Before you start

- **Floating license only** — workstation licenses do not work in Docker.
- **Pin a version tag** — `latest` is not published. Example: `hackolade/hck-cli:8.12.8` (**Ubuntu 26.04 LTS**) or `hackolade/hck-cli:8.12.8-hardened` (Docker Hardened Image). Weekly plugin refreshes may appear as `8.12.8-YYYY-MM-DD` on the [current release only](https://hub.docker.com/r/hackolade/hck-cli/tags). See [image tags](./image-variants.md#image-tags).
- **Re-validate when the image tag changes** — license state is tied to the image UUID.
- **Mount `/data` and `/tmp` on every run** — recommended consolidated layout; legacy `/home/hackolade/…` bind mounts may still work on a writable rootfs (see [Writable paths](#writable-paths-data-and-tmp-recommended)).
- **Always use `docker compose run --rm`** — removes the one-off container when the command exits. Without `--rm`, stopped `…-run-…` containers accumulate and Compose warns about **orphan containers** on the next run.

Need a custom plugin set or your own Dockerfile? See [getting-started.md](./getting-started.md) (legacy `hackolade/studio` build path).

## Quick start

1. Copy a compose file and create a models folder:

```bash
cp compose.hardened.yml compose.local.yml   # or compose.yml for a minimal local run
mkdir -p ./models
```

2. Pull and check the image (`version` is the default service command):

```bash
docker compose -f compose.local.yml pull
docker compose -f compose.local.yml run --rm hck-cli
```

Expect **Hackolade version** plus **Installed plugins** with version, commit, and build date for each bundled plugin:

```text
detected containerized environment and allowed command

Hackolade version: 8.12.7

Installed plugins (40):
  Avro: 0.2.27, commit: d0fda00f, built: 2026-07-03T13:26:23+0000
  BigQuery: 0.2.30, commit: 04fb1148, built: 2026-08-07T09:04:23+0000
  …
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

Offline validation: run **`showComputerIdForOfflineValidation`** — it prints the Computer ID and a **ready-to-open QLM URL** (`is_file=1`, prefilled `is_pcid` and `is_avkey` when `license_key` is configured). Open the URL on a connected machine to download **`LicenseFile.xml`**, then run **`validateKeyOffline`**. Details: [license-validation.md](./license-validation.md).

**Next:** follow the **[offline metadata pipeline example](./example-offline-metadata-pipeline.md)** for a full hardened Compose walkthrough (image upgrade, offline license, revEng → compMod → forweng → genDoc, diagnostics).

## Inspecting the image, license, and logs

Wrapper commands handled by `hck-cli` itself (no full Studio session). Use them in CI and air-gapped pipelines — see the [worked example](./example-offline-metadata-pipeline.md).

| Command | Purpose |
| --- | --- |
| `version` | Studio release in the image + full plugin inventory (name, version, commit, build date) |
| `showLicense` | License installed and valid for **this** image tag? (`--json` for scripts; exit 0 = OK) |
| `listLogs` | List command runs under `/data/logs` (newest first) |
| `showLogs [runId] [--tail N] [--logfile main\|re\|fe\|license]` | Tail logs for one run |

```bash
export COMPOSE="docker compose -f compose.hardened.yml"

$COMPOSE run --rm hck-cli                    # default command: version
$COMPOSE run --rm hck-cli showLicense
$COMPOSE run --rm hck-cli showLicense --json
$COMPOSE run --rm hck-cli listLogs
$COMPOSE run --rm hck-cli showLogs 20260807-143022-revEng --tail 50
$COMPOSE run --rm hck-cli showLogs --logfile license
```

Each CLI job creates **`/data/logs/<YYYYMMDD-HHMMSS>-<command>/`**. Logfile targets: `main` (Hackolade.log), `re` (reverse engineering), `fe` (forward engineering), `license` (HackoladeLicense.log — defaults to last 100 lines when `--tail` is omitted).

Gate a pipeline after validation:

```bash
$COMPOSE run --rm hck-cli showLicense || exit 1
```

## Image tags

| Tag | Meaning |
| --- | --- |
| `hackolade/hck-cli:8.12.8` | Current Studio release (**Ubuntu 26.04 LTS** / Resolute Raccoon) |
| `hackolade/hck-cli:8.12.8-hardened` | Same release, [Docker Hardened Image](https://docs.docker.com/dhi/) (Debian) base |
| `hackolade/hck-cli:8.12.8-2026-08-07` | Example intermediate tag (plugin updates on the current release) |

Update the `image:` line in your compose file, then `docker compose pull`. Ubuntu vs `-hardened`, startup preflight, and arbitrary UID: **[image-variants.md](./image-variants.md)**.

## Docker CLI (without Compose)

See **[docker-cli-howto.md](./docker-cli-howto.md)** for local and hardened `docker run` templates, diagnostics, and artifact extraction.

## Troubleshooting

| Problem | Check |
| --- | --- |
| Permission denied on `./models` | `chown -R 1000:1001 ./models` (default user). For an OpenShift-style UID see [arbitrary UID](./image-variants.md#bind-mounted-host-folders) |
| `The container has no writable location` | Preflight: `/data` and `/tmp` must be writable by this UID. Mount both; keep **group 0** for an arbitrary UID (`group_add: ["0"]`, `user: "<uid>:0"`, or `fsGroup: 0`). Recreate a named volume stuck at `root:root` `755`. Details: [preflight](./image-variants.md#startup-preflight) |
| Fails with read-only rootfs | Mount **`/data`** (volume) and **`/tmp`** (tmpfs) — with `read_only: true`, only these paths are writable |
| `Read-only file system` / writes not landing on a legacy mount | Prefer **`/data/…`** — the image redirects runtime writes to `/data` and `/tmp`; legacy `/home/hackolade/…` bind mounts may still work on a writable rootfs but are not recommended |
| License validation fails | Same image tag for UUID + validation; floating seat available |
| Secret not found | Paths in compose `secrets:` match files on disk |
| Unsure if license is valid | `hck-cli showLicense` or `showLicense --json` |
| Command failed in CI | `hck-cli listLogs` then `showLogs <runId> --logfile re` |
| `Found orphan containers` warning | Past runs without `--rm`; use `docker compose run --rm …` always, then `docker compose -f compose.hardened.yml down --remove-orphans` to clean up |

## See also

- [Image variants, preflight, arbitrary UID](./image-variants.md)
- [Offline metadata pipeline example](./example-offline-metadata-pipeline.md) — **full CI walkthrough**
- [Docker CLI how-to](./docker-cli-howto.md)
- [License validation](./license-validation.md)
- [Custom TLS certificates](./custom-certificates.md)
- [Kubernetes examples](../k8s/README.md)
- [Build your own image](./getting-started.md)
- [Hackolade CLI command reference](https://hackolade.com/help/CommandLineInterface.html)
