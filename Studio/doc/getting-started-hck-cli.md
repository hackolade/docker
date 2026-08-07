# Getting started with `hackolade/hck-cli`

Ready-to-use Docker image: Hackolade Studio CLI, all target plugins, no build step.

![Docker Image Version (latest by date)](https://img.shields.io/docker/v/hackolade/hck-cli)

## Guides

| Guide | Use when |
| --- | --- |
| **This page** | First run, deployment profiles, troubleshooting |
| **[Offline pipeline example](./example-offline-metadata-pipeline.md)** | **Complete CI story** — new image tag, offline license, revEng → compMod → DDL → docs, plus `version`, `showLicense`, `listLogs`, `showLogs` |
| **[Docker CLI how-to](./docker-cli-howto.md)** | You prefer **`docker run`** instead of Compose |
| **[License validation](./license-validation.md)** | Online or offline floating license setup |
| **[Kubernetes](../k8s/README.md)** | Running on K8s / OpenShift |
| **[Custom TLS certificates](./custom-certificates.md)** | Private CAs with read-only PEM mounts |

## Writable paths — `/data` and `/tmp` only

> **Rule:** `hackolade/hck-cli` performs **all runtime writes** to **`/data`** and **`/tmp`** — **nowhere else**.

The image no longer scatters state under `/home/hackolade/...`. Environment variables (XDG base dirs, `DATA_DIR`, `TMPDIR`, …) steer every write to these two mounts. This applies in **every** deployment profile — local Compose, hardened Compose, Kubernetes, and plain `docker run`.

| Path | What gets written there | Persists? |
| --- | --- | --- |
| **`/data`** | License/userData (`/data/app`), command logs (`/data/logs`), models, forward/reverse-engineering output, settings | Yes — use a named volume or PVC |
| **`/tmp`** | Unix sockets, plugin caches, Electron/Chromium scratch, XDG runtime dir | No — tmpfs or memory `emptyDir` |

**Do not mount or expect writes to:**

- `/home/hackolade/.config/Hackolade` (legacy license path — **removed**)
- `/home/hackolade/Documents/HackoladeLogs`, `/home/hackolade/Documents/data`, … (legacy layout)
- Any other bind mount you add outside `/data` or `/tmp`

Put host folders **under `/data`** (e.g. `${PWD}/models:/data/models`). With **`read_only: true`**, the root filesystem is read-only — writes outside `/data` or `/tmp` **fail**.

This is the same rule in [`compose.yml`](../compose.yml), [`compose.hardened.yml`](../compose.hardened.yml), and [`k8s/`](../k8s/) — only the **security profile** (read-only rootfs, caps, user) changes.

## Deployment profiles

| Profile | Compose / manifest | Read-only rootfs | Extra hardening |
| --- | --- | --- | --- |
| **Local** | [`compose.yml`](../compose.yml) | No | Same `/data` + `/tmp` mounts |
| **Hardened** (recommended for CI / production) | [`compose.hardened.yml`](../compose.hardened.yml) | Yes | `cap_drop: ALL`, non-root, no privilege escalation |
| **Kubernetes** | [`k8s/hck-cli-job.yaml`](../k8s/hck-cli-job.yaml) | Yes | Same as hardened Compose (Restricted Pod Security Standard) |

```bash
# Hardened smoke test (recommended baseline for pipelines)
# `version` is the default command — explicit `version` arg is optional
docker compose -f compose.hardened.yml run --rm hck-cli
```

OpenShift arbitrary UID: [`compose.hardened.yml`](../compose.hardened.yml) (`hck-cli-arbitrary-uid`) or [`k8s/hck-cli-job-openshift.yaml`](../k8s/hck-cli-job-openshift.yaml).

## Before you start

- **Floating license only** — workstation licenses do not work in Docker.
- **Pin a version tag** — `latest` is not published. Example: `hackolade/hck-cli:8.12.7`. Weekly plugin refreshes may appear as `8.12.7-YYYY-MM-DD` on the [current release only](https://hub.docker.com/r/hackolade/hck-cli/tags).
- **Re-validate when the image tag changes** — license state is tied to the image UUID.
- **Mount `/data` and `/tmp` on every run** — the image writes **only** to these two paths; nothing else receives runtime data (see [Writable paths](#writable-paths-data-and-tmp-only)).
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
| `hackolade/hck-cli:8.12.7` | Current Hackolade Studio release |
| `hackolade/hck-cli:8.12.7-2026-08-07` | Example intermediate tag (plugin updates on the current release) |

Update the `image:` line in your compose file, then `docker compose pull`.

## Docker CLI (without Compose)

See **[docker-cli-howto.md](./docker-cli-howto.md)** for local and hardened `docker run` templates, diagnostics, and artifact extraction.

## Troubleshooting

| Problem | Check |
| --- | --- |
| Permission denied on `./models` | `chown -R 1000:1001 ./models` |
| Fails with read-only rootfs | Both **`/data`** (volume) and **`/tmp`** (tmpfs) must be mounted — the image writes nowhere else |
| `Read-only file system` / permission denied outside `/data` | Expected — mount the path under **`/data/…`** instead of `/home/hackolade/…` |
| License validation fails | Same image tag for UUID + validation; floating seat available |
| Secret not found | Paths in compose `secrets:` match files on disk |
| Unsure if license is valid | `hck-cli showLicense` or `showLicense --json` |
| Command failed in CI | `hck-cli listLogs` then `showLogs <runId> --logfile re` |
| `Found orphan containers` warning | Past runs without `--rm`; use `docker compose run --rm …` always, then `docker compose -f compose.hardened.yml down --remove-orphans` to clean up |

## See also

- [Offline metadata pipeline example](./example-offline-metadata-pipeline.md) — **full CI walkthrough**
- [Docker CLI how-to](./docker-cli-howto.md)
- [License validation](./license-validation.md)
- [Custom TLS certificates](./custom-certificates.md)
- [Kubernetes examples](../k8s/README.md)
- [Build your own image](./getting-started.md)
- [Hackolade CLI command reference](https://hackolade.com/help/CommandLineInterface.html)
