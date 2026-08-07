This guide will help you get started with the **ready-to-use** Hackolade CLI Docker image (`hackolade/hck-cli`). This image contains Hackolade Studio and all plugins pre-installed, so you can use it directly without building your own image.

![Docker Image Version (latest by date)](https://img.shields.io/docker/v/hackolade/hck-cli)

## ⚠️ Important notes

Before you begin, please note these critical requirements:

- **Floating licenses only**: for Docker, you must have a Hackolade Studio **floating** license type (a.k.a. concurrent license key), as dedicated licenses won't work with Docker
- **License is tied to the Docker image**: Each image version has a unique UUID, so you must validate the license for each version you use. If you change image versions, you'll need to validate the license again for the new image.
- **Always specify version tags**: the `latest` tag is not published. Use `hackolade/hck-cli:8.9.2` or intermediate tags like `8.9.2-YYYY-MM-DD` for plugin updates
- **Use Docker secrets** for license keys in production environments
- **Data paths are simplified**: use `/data/*` instead of `/home/hackolade/Documents/*`

> **🚨 CRITICAL - Plugin Updates Policy:** Plugin updates between releases are **ONLY** available via intermediate tags from the **latest release** (e.g., `hackolade/hck-cli:8.9.2-YYYY-MM-DD`). **Plugin updates will NOT be backported to previous released images.** To get the latest plugin updates, you must use intermediate tags from the most recent release or wait for the next full release.

## What is this image?

The `hackolade/hck-cli` Docker image is a pre-built, production-ready image that includes:
- Hackolade Studio CLI binary (`hck-cli`) -- note that hck-cli in this Docker image replaces the "hackolade" invocation found in the CLI documentation page
- All target plugins pre-installed
- Optimized data volume structure at `/data` (reducing path length and complexity)
- Ready to use immediately - no build step required

**Key advantages:**
- No need to build your own image
- Versioned releases starting from 8.9.2 with optional intermediate tags for plugin updates
- Simplified data paths (`/data` instead of `/home/hackolade/Documents/...`)
- Secure secret management using Docker secrets
- Backward compatible with existing scripts
- Multi-architecture support (AMD64/x86_64 and ARM64) - runs efficiently on macOS Silicon (Apple MX chips) without emulation overhead
- Automatic volume validation - CLI warns if required volumes are not mounted
- Per-command log isolation in `/data/logs` organized as `<date>-command` folders for easier troubleshooting and log analysis

## Differences from building your own image

| Feature | Pre-built Image (`hackolade/hck-cli`) | Building Your Own (hackolade/studio) |
|---------|--------------------------------------|-------------------|
| Setup time | Instant (just pull) | Requires build step |
| Data paths | `/data/*` (simplified) | `/home/hackolade/Documents/*` |
| Entrypoint | `hck-cli` binary | `startup.sh` script |
| Updates | Pull new version | Rebuild image |
| Plugins | All included | Select during build |
| Architecture support | Multi-arch (AMD64 + ARM64) | AMD64/x86_64 only (Intel-based chips) |
| Customization | Limited | Full control |

**When to use the pre-built image:**
- You want to get started quickly
- You need all plugins
- You prefer simplicity over customization
- You're running in CI/CD pipelines
- You're using macOS Silicon (Apple MX) and want efficient ARM64 performance without emulation

**When to build your own:**
- You need specific plugin versions
- You want to customize the image
- You have specific security requirements
- See [build.md](./build.md) for instructions

## Image availability

The image is published on Docker Hub under the `hackolade/hck-cli` repository and will be available for each release of Hackolade Studio alongside the existing `hackolade/studio` image.


**Image naming convention:**
- `hackolade/hck-cli:8.9.2` : Initial release version (starting from 8.9.2)
- `hackolade/hck-cli:8.9.2-YYYY-MM-DD` -:Intermediate tags for plugin updates during the week (e.g., `8.9.2-2025-01-10`)

**Note:** The `latest` tag is not currently published. Always specify a version tag when pulling or referencing the image. If plugins are updated during the week, intermediate tags with the format `X.Y.Z-<date>` may be published to provide access to updated plugins before the next full release.

> **🚨  Plugin Updates Policy:** Plugin updates between releases are **ONLY** available via intermediate tags from the **latest release** (e.g., `hackolade/hck-cli:8.9.2-YYYY-MM-DD`). **Plugin updates will NOT be backported to previous released images.** To get the latest plugin updates, you must use intermediate tags from the most recent release or wait for the next full release.

**Platform support:**
- **AMD64/x86_64** : Linux and Windows (Intel/AMD processors)
- **ARM64** : Linux ARM64 and **macOS Silicon** (Apple MX chips)

Docker automatically pulls the correct architecture image for your platform. If you're running on macOS Silicon (Apple Silicon), Docker Desktop will automatically use the ARM64 image, providing efficient performance without emulation overhead.

## Prerequisites

Before you begin, make sure you have:
1. **Docker installed** on your system ([Install Docker](https://www.docker.com/get-started))
   - **macOS Silicon users:** Docker Desktop for Mac includes ARM64 support
2. **Docker Compose** installed (v2.0+ recommended)
3. **Docker is running** (check by running `docker --version` in your terminal)
4. A **floating Hackolade license key** (required for Docker CLI usage)

**Note for macOS Silicon users:** The image includes ARM64 support, so it runs efficiently on Apple Silicon Macs (MX) without emulation overhead. Docker Desktop automatically selects the correct architecture.

## Understanding the image structure

### Entrypoint

The image uses `hck-cli` as its default entrypoint - a simple binary that executes Hackolade CLI commands directly. This provides the most straightforward and efficient way to run commands.

### Data Volume Structure

The image is designed for a **read-only root filesystem**. Runtime writes go to exactly two places:

| Mount | Purpose |
| --- | --- |
| `/data` | Persistent volume: license/userData (`/data/app`), logs, models, output, settings, options |
| `/tmp` | tmpfs: sockets, caches, and scratch files (discarded when the container exits) |

Layout under `/data`:

- `/data/app` - Application data (license state, Electron userData). Lives on the `/data` volume via `XDG_CONFIG_HOME`.
- `/data/models` - Your input model files
- `/data/output` - Generated artifacts (documentation, schemas, etc.)
- `/data/logs` - Application logs organized in `<date>-command` folders (e.g., `2024-01-15-genDoc`) for per-command isolation and troubleshooting
- `/data/options` - (Optional) User-defined configurations
- `/data/settings` - Optional settings

**⚠️ MANDATORY:** Mount a volume at `/data` **and** a writable `/tmp` (tmpfs recommended). Without `/data`, licensing and configuration will not persist. Without `/tmp`, Electron and scratch I/O will fail under `read_only: true`.

**Breaking change:** Earlier releases required a separate volume at `/home/hackolade/.config`. That path is no longer written; migrate the named volume to `/data` (license state is under `/data/app`).

**Volume validation:** The CLI automatically validates that required mounts are writable. If a required mount is missing, the CLI will display a warning (or fail in the official image) before command execution.

**Log isolation:** Logs are automatically organized per command in `/data/logs` using folders named `<date>-command` (e.g., `2024-01-15-genDoc`, `2024-01-15-forweng`). This folder structure provides proper command isolation, making it easier to analyze logs for specific commands when troubleshooting issues.

## Quick start with Docker Compose

The easiest way to use this image is with Docker Compose. We provide two example files:

| File | Use when |
| --- | --- |
| [`compose.yml`](../compose.yml) | Getting started locally — minimal configuration, single `/data` volume |
| [`compose.hardened.yml`](../compose.hardened.yml) | Production or CI — read-only root filesystem, dropped capabilities, `/data` + `/tmp` tmpfs (matches Kubernetes Restricted) |

**Important:** Both files are designed for the **pre-built `hackolade/hck-cli` image**. They use `/data/*` paths and the `hck-cli` binary entrypoint, which differ from compose files used with custom-built images.

### Step 1: Set Up Your Compose File

**Option A: Copy the provided compose file** (recommended for first use)

Copy [`compose.yml`](../compose.yml) to your working directory:

```bash
cp compose.yml /path/to/your/working/directory/
```

**Option B: Use the hardened compose file** (recommended for production / Kubernetes parity)

Copy [`compose.hardened.yml`](../compose.hardened.yml) instead, or alongside `compose.yml`:

```bash
cp compose.hardened.yml /path/to/your/working/directory/
docker compose -f compose.hardened.yml run --rm hck-cli version
```

**Option C: Create your own compose file**

See [`compose.yml`](../compose.yml) for a simple example and [`compose.hardened.yml`](../compose.hardened.yml) for the restricted profile.

The compose files include:
- `hck-cli` service — main service for running CLI commands
- `showComputerIdForOfflineValidation` — computer ID for offline license validation
- `validateKeyOnline` / `validateKeyOffline` — license validation via Docker secrets
- A single named volume at `/data` (license state, logs, models, output, settings)
- Secret definitions for license key and license file
- (`compose.hardened.yml` only) read-only root filesystem, `cap_drop: ALL`, and `/tmp` tmpfs

### Step 2: Create Your Models Directory

Create a directory for your model files:

```bash
mkdir -p ./models
chown -R 1000:1001 ./models
```

**Why `chown 1000:1001`?** The container runs as user `hackolade` with UID 1000 and GID 1001 (data-modelers group). This ensures the folder is writable by the container.

### Step 3: Pull the Image

Pull the image from Docker Hub using Docker Compose. Always specify a version tag (the `latest` tag is not available):

```bash
docker compose pull
```

This will pull the image version specified in your `compose.yml` file (`hackolade/hck-cli:8.9.2`). For intermediate releases with plugin updates, update the image tag in your `compose.yml` to the date-based tag (e.g., `hackolade/hck-cli:8.9.2-2025-01-10`) and run `docker compose pull` again.

### Step 4: Validate Your License

Before using the CLI, you must validate your license.  This step must be performed for each new image, but only needs to be performed once. After validation has successfully completed, then all successions of commands can be orchestrated and invoked without having to validate the license key again.  

The compose file provides secure methods using Docker secrets. Choose the method that matches your environment:

#### Online License Validation (Recommended)

Use this method if your server has internet access.

**Step 4a: Prepare your license key file**

Create a file containing the floating license key you purchased for Docker. The path `${HOME}/Downloads/license-key.txt` is just an example. You can use any path you prefer, but make sure it matches the path in your `compose.yml` secrets section:

```bash
# Example: Using ${HOME}/Downloads (adjust path as needed)
echo "YOUR-LICENSE-KEY" > ${HOME}/Downloads/license-key.txt
chmod 600 ${HOME}/Downloads/license-key.txt
```

**Step 4b: Validate the license**

```bash
docker compose run --rm validateKeyOnline
```

The compose file automatically:
- Reads your license key from the secret file (path specified in `compose.yml` secrets section, e.g., `${HOME}/Downloads/license-key.txt`)
- Uses the correct network mode for online validation (`network_mode: host`)
- Stores the validated license in the persistent volume

**Note:** For online validation, you don't need to get the computer ID separately. The validation process handles it automatically.

#### Offline License Validation

Use this method if your server has no internet access.

**Step 4a: Get the computer ID**

First, get the computer ID (UUID) that will be used to generate the offline license file:

```bash
docker compose run --rm showComputerIdForOfflineValidation
```

Copy the UUID that's displayed (e.g., `420d1eaf-6e08-4e12-b4d1-103ab86565b4-0eec2df9-f40e-4623-9567-c2c287c95d0c-docker`). Note that Docker images will have the `-docker` suffix in the UUID.

**Step 4b: Generate the license file**

From a computer with internet access, open your browser and go to:
[https://quicklicensemanager.com/hackolade/QlmCustomerSite](https://quicklicensemanager.com/hackolade/QlmCustomerSite)

Fill in the form:
- **Activation Key**: Enter your floating license key
- **Version**: Leave empty (or select the appropriate version if required)
- **Computer ID**: Enter the UUID from step 4a
- **Options**: Check both "Generate a license file" and "I consent to the Privacy Policy"
- Click the **Activate** button

A file named **LicenseFile.xml** will be downloaded. **Do NOT edit or alter this file**. It contains integrity validation to prevent abuse.

**Step 4c: Prepare the license file**

Copy the **LicenseFile.xml** file to your server. The path `${HOME}/Downloads/LicenseFile.xml` is just an example. Use the path that matches your `compose.yml` secrets section:

```bash
# Example: Using ${HOME}/Downloads (adjust path to match your compose.yml)
cp LicenseFile.xml ${HOME}/Downloads/LicenseFile.xml
chmod 600 ${HOME}/Downloads/LicenseFile.xml
```

**Step 4d: Validate the license**

```bash
docker compose run --rm validateKeyOffline
```

The compose file automatically:
- Reads the license file from the secret (`${HOME}/Downloads/LicenseFile.xml`)
- Uses `network_mode: 'none'` to ensure no network access
- Stores the validated license in the persistent volume

**Important:** The license is tied to the specific Docker image. You must use the **same Docker image** (same tag/version) for steps 4a and 4d, otherwise the UUIDs won't match and validation will fail. If you change the image version, you'll need to generate a new license file for that image.

For more detailed offline validation instructions, see [license-validation.md](./license-validation.md).

### Step 5: Run CLI Commands

Now you're ready to run Hackolade CLI commands!

**Basic command structure:**
```bash
docker compose run --rm hck-cli COMMAND [OPTIONS]
```

**Example: Check version**
```bash
docker compose run --rm hck-cli version
```

**Example: Show help**
```bash
docker compose run --rm hck-cli help
```

**Example: Generate documentation**
```bash
docker compose run --rm hck-cli genDoc \
  --format=HTML \
  --model '/data/models/MongoDB/Yelp Challenge dataset.hck.json' \
  --doc /data/output/doc-test \
  --jsonSchema
```

**Example: Forward engineering**
```bash
docker compose run --rm hck-cli forweng \
  --model /data/models/model.json \
  --jsonschemacompliance full \
  --skipUndefinedLevel \
  --structuredpath false \
  --path /data/output/ \
  --outputtype jsonschema
```

## Hardened Docker Compose (Kubernetes parity)

For production clusters or CI pipelines that enforce the Kubernetes **Restricted** Pod Security Standard (or OpenShift **restricted-v2** SCC), use [`compose.hardened.yml`](../compose.hardened.yml). It adds:

- `read_only: true` — read-only root filesystem
- `cap_drop: [ALL]` and `no-new-privileges` — no extra capabilities or privilege escalation
- `user: "1000:1001"` — non-root (OpenShift arbitrary UID variant included as `hck-cli-arbitrary-uid`)
- `/data` named volume — persistent state (same as `compose.yml`)
- `/tmp` tmpfs — scratch, sockets, and caches (discarded when the container exits)

```bash
# Smoke test
docker compose -f compose.hardened.yml run --rm hck-cli version

# OpenShift-style arbitrary UID
docker compose -f compose.hardened.yml run --rm hck-cli-arbitrary-uid version

# Command that writes output (requires a model at ./models/smoke.hck.json)
docker compose -f compose.hardened.yml run --rm genDoc
```

## Using Docker CLI directly

If you prefer using Docker CLI directly instead of Docker Compose, here's how:

### Basic Command Structure

```bash
docker run --rm --read-only \
  --cap-drop=ALL --security-opt=no-new-privileges \
  --user 1000:1001 \
  -v hackolade-studio-data:/data \
  -v ${PWD}/models:/data/models \
  --tmpfs /tmp:rw,size=1g,mode=1777 \
  hackolade/hck-cli:8.9.2 COMMAND [OPTIONS]
```

### Create Required Volumes

First, create the named volume for persistent state:

```bash
docker volume create hackolade-studio-data
```

`/tmp` should be a tmpfs (shown above), not a named volume.

### Example Commands

**Check version:**
```bash
docker run --rm --read-only \
  --user 1000:1001 \
  -v hackolade-studio-data:/data \
  --tmpfs /tmp:rw,size=1g,mode=1777 \
  hackolade/hck-cli:8.9.2 version
```

**Get computer ID:**
```bash
docker run --rm --read-only \
  --user 1000:1001 \
  -v hackolade-studio-data:/data \
  --tmpfs /tmp:rw,size=1g,mode=1777 \
  hackolade/hck-cli:8.9.2 getComputerId
```

**Generate documentation:**
```bash
docker run --rm --read-only \
  --user 1000:1001 \
  -v hackolade-studio-data:/data \
  -v ${PWD}/models:/data/models \
  --tmpfs /tmp:rw,size=1g,mode=1777 \
  hackolade/hck-cli:8.9.2 genDoc \
  --format=HTML \
  --model /data/models/model.json \
  --doc /data/output/doc.html
```
In case of offline validation:
```bash
docker run --rm --read-only \
  --user 1000:1001 \
  -v hackolade-studio-data:/data \
  -v ${PWD}/models:/data/models \
  -v ${PWD}/LicenseFile.xml:/data/LicenseFile.xml:ro \
  --tmpfs /tmp:rw,size=1g,mode=1777 \
  hackolade/hck-cli:8.9.2 genDoc \
  --format=HTML \
  --model /data/models/model.json \
  --doc /data/output/doc.html
```

## Security best practices

### Using Docker Secrets for License Keys

The compose file uses Docker secrets to securely manage license keys and files. This is the **recommended approach** for production environments.

**Benefits:**
- Secrets are not exposed in command-line arguments
- Secrets are not visible in `docker ps` or container logs
- Secrets are managed by Docker and can be rotated easily
- Secrets are only available to services that explicitly request them

**How it works:**

1. **Define secrets in compose.yml:**
   ```yaml
   secrets:
     license_key: # Don't change the name of the secret!
       file: ${HOME}/Downloads/license-key.txt  # Example path - use any path you prefer
     license_file: # Don't change the name of the secret!
       file: ${HOME}/Downloads/LicenseFile.xml  # Example path - use any path you prefer
   ```

2. **Reference secrets in services:**
   ```yaml
   validateKeyOnline:
     secrets:
       - license_key
   ```

3. **The CLI automatically reads from standard secret paths:**
   - License key: `/run/secrets/license_key`
   - License file: `/run/secrets/license_file`

**Securing your secret files:**

```bash
# Set restrictive permissions on secret files (adjust paths to match your compose.yml)
chmod 600 ${HOME}/Downloads/license-key.txt
chmod 600 ${HOME}/Downloads/LicenseFile.xml

# Consider using a more secure location (update compose.yml accordingly)
mkdir -p ~/.hackolade/secrets
chmod 700 ~/.hackolade/secrets
```

### Alternative: Environment Variables (Less Secure)

While you can pass license keys via environment variables, this is **not recommended** for production:

```bash
# NOT RECOMMENDED for production
docker run --rm \
  -e LICENSE_KEY="your-key-here" \
  hackolade/hck-cli:8.9.2 validateKey --key ${LICENSE_KEY}
```

**Why secrets are better:**
- Environment variables appear in process lists
- Environment variables can be logged
- Environment variables are harder to rotate

### Network Security

For maximum security, use `network_mode: 'none'` when validating licenses offline:

```yaml
validateKeyOffline:
  network_mode: 'none'
  secrets:
    - license_file
```

This ensures the container has no network access during offline validation.

## Common scenarios

### Scenario 1: Generate Documentation

```bash
docker compose run --rm hck-cli genDoc \
  --format=HTML \
  --model /data/models/my-model.hck.json \
  --doc /data/output/documentation \
  --jsonSchema
```

### Scenario 2: Forward Engineering

```bash
docker compose run --rm hck-cli forweng \
  --model /data/models/my-model.hck.json \
  --jsonschemacompliance full \
  --skipUndefinedLevel \
  --structuredpath false \
  --path /data/output/schemas/ \
  --outputtype jsonschema
```

### Scenario 3: Reverse Engineering

```bash
docker compose run --rm hck-cli revEng \
  --target=MONGODB \
  --connectFile=/data/models/connection.bin \
  --model=/data/output/reverse-engineered-model.json \
  --selectedObjects="database_name" \
  --inferRelationships=true
```

### Scenario 4: Compare Models

```bash
docker compose run --rm hck-cli compMod \
  --model1=/data/models/model-v1.json \
  --model2=/data/models/model-v2.json \
  --deltamodel=/data/output/delta.json
```

## Retrieving generated files

After running commands, retrieve files from Docker volumes (if you used named volumes):

**Retrieve output files:**
```bash
docker run --rm --init \
  --name hackolade-data-extractor \
  -u root \
  -v hackolade-studio-output:/output \
  -v ${PWD}/output:/output-on-host \
  --entrypoint cp \
  hackolade/hck-cli:8.9.2 -r /output /output-on-host/.
```

**Retrieve log files:**
```bash
docker run --rm --init \
  --name hackolade-log-extractor \
  -u root \
  -v hackolade-studio-logs:/logs \
  -v ${PWD}/logs:/logs-on-host \
  --entrypoint cp \
  hackolade/hck-cli:8.9.2 -r /logs /logs-on-host/.
```

**Log organization:** Logs in `/data/logs` are automatically organized in folders using the format `<date>-command` (e.g., `2024-01-15-genDoc`, `2024-01-15-forweng`). This structure makes it easy to isolate and analyze logs for specific operations by date and command type. When troubleshooting issues, you can focus on logs from the specific command and date that encountered a problem.

## Troubleshooting

### Permission Denied Errors

If you get permission errors with bind-mounted folders (like `./models`), ensure correct permissions:

```bash
chown -R 1000:1001 ./models
chown -R 1000:1001 ./output
```

**Note:** The container runs as numeric user `1000:1001` by default (compatible with Kubernetes `runAsNonRoot`). OpenShift-style arbitrary UIDs in group 0 are also supported when `/data` is group-writable.

**Note:** Docker named volumes (like `hackolade-studio-data`) don't require permission changes on the host. Bind mounts for models should be owned by UID 1000 (or writable by group 0).

### Volume Not Found

If Docker says a volume doesn't exist, create it:

```bash
docker volume create hackolade-studio-data
```

Or let Docker Compose create it automatically on first run. Ensure every run also mounts a writable `/tmp` (compose uses `tmpfs`).

### Volume Validation Warnings

The CLI automatically checks for required writable mounts and will warn you if they're not properly mounted. If you see warnings about missing mounts:

1. **Check your compose.yml or docker run command** - Ensure:
   - `hackolade-studio-data` → `/data` ⚠️ **MANDATORY** - license state, logs, output, settings
   - tmpfs (or equivalent) → `/tmp` ⚠️ **MANDATORY** under `read_only: true`
   - Optional bind: host `models` → `/data/models`

2. **Verify volumes exist:**
   ```bash
   docker volume ls | grep hackolade-studio
   ```

3. **Check volume mounts in running containers:**
   ```bash
   docker inspect <container-name> | grep -A 10 Mounts
   ```

4. **Review the warning message** - The CLI will indicate which specific mount is missing and what it's used for.

**Important:** A single `/data` volume plus `/tmp` tmpfs replaces the older multi-volume layout (`/home/hackolade/.config`, separate logs/output volumes). Migrate by mounting your persistent state at `/data`.

### License Validation Failed

- Make sure you're using the same image tag for getting UUID and validating
- Check that you're using a floating license key (not a workstation license)
- Ensure the license has available seats
- Verify secret files exist and have correct permissions

### Secret File Not Found

If Docker Compose can't find your secret files:

1. Check the file paths in `compose.yml` match your actual file locations (note: `${HOME}/Downloads/` is just an example - use your actual paths)
2. Ensure the files exist at the paths specified in your `compose.yml`:
   ```bash
   # Example paths - adjust to match your compose.yml secrets section
   ls -la ${HOME}/Downloads/license-key.txt
   ls -la ${HOME}/Downloads/LicenseFile.xml
   ```
3. Verify file permissions (adjust paths to match your compose.yml):
   ```bash
   chmod 600 ${HOME}/Downloads/license-key.txt
   chmod 600 ${HOME}/Downloads/LicenseFile.xml
   ```

### Image Not Found

If you get "image not found" errors:

1. **If using Docker Compose**, pull the image:
   ```bash
   docker compose pull
   ```

2. **If using Docker CLI directly**, pull the image explicitly with a version tag (the `latest` tag is not available):
   ```bash
   docker pull hackolade/hck-cli:8.9.2
   ```

3. Check available tags on [Docker Hub](https://hub.docker.com/r/hackolade/hck-cli/tags)

4. Verify your Docker Hub access (the image may require authentication)

5. If you need an intermediate release with plugin updates, update the image tag in your `compose.yml` (or use `docker pull` with the date-based tag):
   ```bash
   docker pull hackolade/hck-cli:8.9.2-2025-01-10
   ```

### Platform/Architecture Verification

To verify that Docker is using the correct architecture for your platform:

**Check your system architecture:**
```bash
# macOS/Linux
uname -m

# Expected outputs:
# - x86_64 (Intel Macs, Linux AMD64)
# - arm64 (Apple Silicon Macs, Linux ARM64)
```

**Verify the pulled image architecture:**
```bash
docker image inspect hackolade/hck-cli:8.9.2 | grep Architecture
```

**macOS Silicon users:** If you see `amd64` instead of `arm64`, Docker may be using emulation. To force ARM64 architecture:
```bash
docker pull --platform linux/arm64 hackolade/hck-cli:8.9.2
```

Or in your `compose.yml`, specify the platform:
```yaml
services:
  hck-cli:
    image: hackolade/hck-cli:8.9.2
    platform: linux/arm64  # For Apple Silicon
    # platform: linux/amd64  # For Intel/AMD
```

**Note:** Docker Desktop for Mac automatically selects the correct architecture, so manual platform specification is usually not needed.



## Next steps

- Read [license-validation.md](./license-validation.md) for detailed license validation instructions
- **Need to install custom TLS certificates?** See [custom-certificates.md](./custom-certificates.md) for instructions on installing custom certificates in containers
- **Need to build a custom image?** See [getting-started.md](./getting-started.md) for instructions on building your own image with selected plugins
- Read [build.md](./build.md) for advanced build configurations
- Check the [Hackolade CLI documentation](https://hackolade.com/help/CommandLineInterface.html) for all available commands
- See [interactive-sessions.md](./interactive-sessions.md) for debugging and development workflows

## Quick reference

### Docker Compose Commands

```bash
# Pull the image (pulls the version specified in compose.yml)
docker compose pull

# Check version
docker compose run --rm hck-cli version

# Get computer ID
docker compose run --rm showComputerIdForOfflineValidation

# Validate license (online)
docker compose run --rm validateKeyOnline

# Validate license (offline)
docker compose run --rm validateKeyOffline

# Run any CLI command
docker compose run --rm hck-cli COMMAND [OPTIONS]
```

### Docker CLI Commands

```bash
# Pull the image (always specify a version tag)
docker pull hackolade/hck-cli:8.9.2

# Create volumes
docker volume create hackolade-studio-data

# Run command
docker run --rm --read-only \
  --user 1000:1001 \
  -v hackolade-studio-data:/data \
  -v ${PWD}/models:/data/models \
  --tmpfs /tmp:rw,size=1g,mode=1777 \
  hackolade/hck-cli:8.9.2 COMMAND
```

## Kubernetes (restricted / read-only rootfs)

Example manifests live in [`k8s/`](../k8s/). They mirror `compose.hardened.yml`: `readOnlyRootFilesystem`, non-root, dropped capabilities, a **PVC at `/data`**, and a **memory `emptyDir` at `/tmp`**.

| Manifest | Purpose |
| --- | --- |
| [`k8s/hck-cli-job.yaml`](../k8s/hck-cli-job.yaml) | Smoke test (`version`) with PVC + `/tmp` emptyDir |
| [`k8s/hck-cli-job-openshift.yaml`](../k8s/hck-cli-job-openshift.yaml) | Same, for OpenShift `restricted-v2` (arbitrary UID, `fsGroup: 0`) |
| [`k8s/hck-cli-gendoc-job.yaml`](../k8s/hck-cli-gendoc-job.yaml) | Generate documentation from a model on the PVC |

Apply the standard restricted example:

```bash
kubectl apply -f k8s/hck-cli-job.yaml
kubectl logs job/hck-cli-version
```

Minimal Job excerpt (full file includes the PVC):

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: hck-cli-version
  labels:
    pod-security.kubernetes.io/enforce: restricted
spec:
  template:
    metadata:
      labels:
        pod-security.kubernetes.io/enforce: restricted
    spec:
      restartPolicy: Never
      automountServiceAccountToken: false
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        runAsGroup: 1001
        fsGroup: 0
        seccompProfile:
          type: RuntimeDefault
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: hck-cli-data
        - name: tmp
          emptyDir:
            medium: Memory
            sizeLimit: 1Gi
      containers:
        - name: hck-cli
          image: hackolade/hck-cli:8.9.2
          args: ["version"]
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop: ["ALL"]
          volumeMounts:
            - name: data
              mountPath: /data
            - name: tmp
              mountPath: /tmp
```

See [`k8s/README.md`](../k8s/README.md) for OpenShift and genDoc variants.

## Backward compatibility with other images

For users migrating from the `hackolade/studio` image or custom-built images that use `startup.sh` as the entrypoint, this image maintains backward compatibility by including the `startup.sh` and `show-computer-id.sh` scripts.

You can override the entrypoint to use these scripts if needed:

```bash
# Use show-computer-id.sh script (alternative to getComputerId command)
docker run --rm --entrypoint show-computer-id.sh hackolade/hck-cli:8.9.2

# Use startup.sh script (alternative to direct hck-cli entrypoint)
docker run --rm --entrypoint startup.sh hackolade/hck-cli:8.9.2 COMMAND [OPTIONS]
```

**Note:** While these scripts are available for compatibility, the recommended approach is to use the `hck-cli` binary directly as the entrypoint, which provides better performance and simpler usage.
