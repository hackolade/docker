# Example: offline license + metadata pipeline (hardened Compose)

**Part of:** [Getting started](./getting-started-hck-cli.md) · [All guides](../README.md#documentation)

End-to-end story using [`compose.hardened.yml`](../compose.hardened.yml): a new `hackolade/hck-cli` image is available, your runner has **no Internet**, and you want to refresh a production model, diff it against a baseline, then publish **DDL** and **documentation**.

Every step uses the hardened profile (read-only rootfs) with **consolidated `/data` + `/tmp` mounts** (recommended over legacy `/home/hackolade/…` paths).

```bash
cd /path/to/docker/Studio
export COMPOSE="docker compose -f compose.hardened.yml"
# Always: $COMPOSE run --rm <service> …  (--rm avoids orphan container warnings)
```

---

## Scenario

| Item | Value in this example |
| --- | --- |
| Previous image | `hackolade/hck-cli:8.9.2` (licensed on the old tag) |
| New image | `hackolade/hck-cli:8.12.7` (needs a new offline license file) |
| Environment | Air-gapped runner; **internal** network to the database for reverse engineering |
| Baseline model | Git-tracked `production-v1.hck.json` |
| Goal | RE v2 → delta vs v1 → DDL + docs |

---

## 0. Prepare the workspace

Update the image tag in `compose.hardened.yml`, then lay out inputs:

```text
models/
├── baseline/
│   └── production-v1.hck.json
├── connections/
│   └── mongodb-atlas.bin          # exported from Hackolade Studio
└── workspace/                     # optional host mirror of outputs
```

```bash
mkdir -p models/{baseline,connections,workspace}
chown -R 1000:1001 models

cp /from/git/production-v1.hck.json models/baseline/
cp /from/studio/mongodb-atlas.bin models/connections/

$COMPOSE pull
```

### What is installed?

```bash
$COMPOSE run --rm hck-cli
```

The default command is **`version`**. Output includes the Studio release and every bundled plugin:

```text
Hackolade version: 8.12.7

Installed plugins (40):
  Avro: 0.2.27, commit: d0fda00f, built: 2026-07-03T13:26:23+0000
  BigQuery: 0.2.30, commit: 04fb1148, built: 2026-08-07T09:04:23+0000
  …
```

Expect **`8.12.7`** after you update the image tag in the compose file.

### Is the license ready for this image?

Before activating the new tag, check persisted license state (read-only — does not start Studio):

```bash
$COMPOSE run --rm hck-cli showLicense
```

Expect **`installed: missing`** or warnings that the CLI image id does not match — normal when upgrading tags. Use **`--json`** in CI for machine-readable output:

```bash
$COMPOSE run --rm hck-cli showLicense --json
```

Exit code `0` means installed and healthy; `1` means missing, partial, or expired.

---

## 1. Offline license for the new image

Each image tag has its own container UUID. Upgrading **`8.9.2` → `8.12.7`** requires a new offline activation even if the floating key is unchanged.

### 1a. Computer ID + QLM URL (air-gapped server)

```bash
$COMPOSE run --rm showComputerIdForOfflineValidation
```

The service runs **`getComputerId`**. Example output:

```text
📋 Copy the Computer ID below and use it for offline license activation:

afa10d9e-17cd-48d7-97f5-b277951773ec-b572e4e5-6796-4cf7-820e-62a30530a318-8.12.7-docker

🌐 Open the following URL in your browser to proceed with offline validation:
   https://quicklicensemanager.com/hackolade/qlmcustomersite/qlmwebactivation.aspx?is_file=1&is_pcid=afa10d9e-17cd-48d7-97f5-b277951773ec-b572e4e5-6796-4cf7-820e-62a30530a318-8.12.7-docker&is_avkey=YOUR-FLOATING-LICENSE-KEY
   (activation key prefilled from license key / secrets)
```

The Computer ID encodes the **image UUID**, **container UUID**, **Studio version**, and a **`-docker`** suffix. The QLM URL is ready to use: **`is_file=1`** triggers **`LicenseFile.xml`** download, **`is_pcid`** is prefilled with the Computer ID, and **`is_avkey`** is prefilled when the `license_key` secret is configured in compose — open the link on a connected machine and confirm; no manual form fill needed.

### 1b. Download `LicenseFile.xml` (Internet-connected machine)

Open the URL from step 1a in a browser on any machine with Internet access. QLM downloads **`LicenseFile.xml`** automatically — no need to fill the form manually when the URL is complete.

**Do not edit** the downloaded file.

Copy it to the path expected by `compose.hardened.yml`:

```yaml
secrets:
  license_file:
    file: ${HOME}/Downloads/LicenseFile.xml
```

### 1c. Validate offline

```bash
$COMPOSE run --rm validateKeyOffline
```

Confirm:

```bash
$COMPOSE run --rm hck-cli showLicense
```

You should see **`installed: installed`**, offline mode, and **`cliImageIdMatchesCurrent: true`**.

More detail: [license-validation.md](./license-validation.md).

---

## 2. Reverse-engineer production (model v2)

The runner has no Internet but can reach the database internally. Offline validation uses `network_mode: none`; **`hck-cli` keeps default networking** for `revEng`.

```bash
$COMPOSE run --rm hck-cli revEng \
  --target=MONGODB \
  --connectFile=/data/models/connections/mongodb-atlas.bin \
  --model=/data/output/workspace/production-v2.hck.json \
  --selectedObjects="sample_mflix" \
  --inferRelationships=true \
  --samplingValue=10
```

If something fails, inspect logs (each run gets a folder under **`/data/logs`**):

```bash
# List recent command runs (newest first)
$COMPOSE run --rm hck-cli listLogs

# Show logs for a run — use runId from listLogs, e.g. 20260807-143022-revEng
$COMPOSE run --rm hck-cli showLogs 20260807-143022-revEng --tail 50

# Reverse-engineering log file specifically
$COMPOSE run --rm hck-cli showLogs 20260807-143022-revEng --logfile re --tail 100

# License-related lines (defaults to last 100 lines)
$COMPOSE run --rm hck-cli showLogs --logfile license
```

**`showLogs` logfile targets:** `main` (Hackolade.log), `re` (HackoladeRe.log), `fe` (HackoladeFe.log), `license` (HackoladeLicense.log).

---

## 3. Compare baseline vs production (delta model)

```bash
$COMPOSE run --rm hck-cli compMod \
  --model1=/data/models/baseline/production-v1.hck.json \
  --model2=/data/output/workspace/production-v2.hck.json \
  --deltamodel=/data/output/delta/production-delta.hck.json
```

On failure: `listLogs` → `showLogs <runId>` as above.

---

## 4. Forward-engineer DDL from the new model

```bash
$COMPOSE run --rm hck-cli forweng \
  --model=/data/output/workspace/production-v2.hck.json \
  --path=/data/output/ddl/ \
  --outputtype=ddl \
  --jsonschemacompliance=full \
  --skipUndefinedLevel \
  --structuredpath=false
```

Adjust `--outputtype` and flags for your target plugin — see the [CLI reference](https://hackolade.com/help/CommandLineInterface.html).

Forward-engineering logs: `showLogs <runId> --logfile fe`.

---

## 5. Generate documentation

**HTML:**

```bash
$COMPOSE run --rm hck-cli genDoc \
  --format=HTML \
  --model=/data/output/workspace/production-v2.hck.json \
  --doc=/data/output/docs/production-v2.html \
  --jsonSchema
```

**PDF:**

```bash
$COMPOSE run --rm hck-cli genDoc \
  --format=PDF \
  --model=/data/output/workspace/production-v2.hck.json \
  --doc=/data/output/docs/production-v2.pdf
```

---

## 6. Collect artifacts

```text
/data/output/   (on volume hackolade-studio-data)
├── workspace/production-v2.hck.json
├── delta/production-delta.hck.json
├── ddl/
└── docs/
```

```bash
mkdir -p ./artifacts
docker run --rm --user root \
  -v hackolade-studio-data:/data:ro \
  -v "${PWD}/artifacts:/host" \
  --entrypoint cp \
  hackolade/hck-cli:8.12.7 -r /data/output/. /host/
```

---

## Diagnostic commands (quick reference)

| Command | Purpose |
| --- | --- |
| `version` | Studio release + full plugin inventory (name, version, commit, build date) |
| `showLicense` | License installed? Matches current image? (`--json` for CI) |
| `listLogs` | List command runs under `/data/logs` (newest first) |
| `showLogs [runId] [--tail N] [--logfile main\|re\|fe\|license]` | Tail logs for one run |

All are **`hck-cli` wrapper commands** — they run without spawning a full Studio session and work with the hardened compose file:

```bash
$COMPOSE run --rm hck-cli                       # default: version
$COMPOSE run --rm hck-cli showLicense
$COMPOSE run --rm hck-cli listLogs
$COMPOSE run --rm hck-cli showLogs --logfile license
```

---

## Pipeline summary

```bash
$COMPOSE pull
$COMPOSE run --rm hck-cli                       # version + plugin list
$COMPOSE run --rm hck-cli showLicense          # before: missing / wrong image id

$COMPOSE run --rm showComputerIdForOfflineValidation   # Computer ID + QLM URL → download LicenseFile.xml
# … copy LicenseFile.xml to the server …
$COMPOSE run --rm validateKeyOffline
$COMPOSE run --rm hck-cli showLicense          # after: installed

$COMPOSE run --rm hck-cli revEng …
$COMPOSE run --rm hck-cli listLogs              # if needed
$COMPOSE run --rm hck-cli showLogs <runId> …

$COMPOSE run --rm hck-cli compMod …
$COMPOSE run --rm hck-cli forweng …
$COMPOSE run --rm hck-cli genDoc …
```

| Step | Compose service | Notes |
| --- | --- | --- |
| Version / RE / FE / docs | `hck-cli` | Pass command as container `command` or CLI args |
| Computer ID + QLM URL | `showComputerIdForOfflineValidation` | Opens prefilled URL on a connected machine to download `LicenseFile.xml` |
| Offline license | `validateKeyOffline` | `network_mode: none` + secret |

Same **`/data` + `/tmp`** layout as [`compose.yml`](../compose.yml) and [`k8s/`](../k8s/) — hardened only adds read-only rootfs and dropped capabilities.

---

## See also

- [Getting started with hck-cli](./getting-started-hck-cli.md)
- [License validation](./license-validation.md)
- [Hackolade CLI command reference](https://hackolade.com/help/CommandLineInterface.html)
