This guide will help you get started with the **ready-to-use** Hackolade CLI Docker image (`hackolade/hck-cli`). This image contains Hackolade Studio and all plugins pre-installed, so you can use it directly without building your own image.

![Docker Image Version (latest by date)](https://img.shields.io/docker/v/hackolade/hck-cli)

## ⚠️ Important notes

Before you begin, please note these critical requirements:

- **Concurrent licenses only**: for Docker, you must have a Hackolade Studio **concurrent** license type, as dedicated licenses won't work with Docker
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
4. A **concurrent Hackolade license key** (required for Docker CLI usage)

**Note for macOS Silicon users:** The image includes ARM64 support, so it runs efficiently on Apple Silicon Macs (MX) without emulation overhead. Docker Desktop automatically selects the correct architecture.

## Understanding the image structure

### Entrypoint

The image uses `hck-cli` as its default entrypoint - a simple binary that executes Hackolade CLI commands directly. This provides the most straightforward and efficient way to run commands.

### Data Volume Structure

The image uses a simplified data structure with volumes mounted directly under `/data`:

- `/data/models` - Your input model files
- `/data/output` - Generated artifacts (documentation, schemas, etc.)
- `/data/logs` - Application logs organized in `<date>-command` folders (e.g., `2024-01-15-genDoc`) for per-command isolation and troubleshooting
- `/data/options` - (Optional) User-defined configurations

**⚠️ MANDATORY:** The application data folder (`/home/hackolade/.config`) **MUST** be mounted as a volume. This volume is absolutely required for licensing and configuration to work properly. Without this volume mounted, the CLI will not function correctly.

This structure reduces path length and simplifies volume management compared to the previous `/home/hackolade/Documents/...` structure.

**Volume validation:** The CLI automatically validates that required volumes are properly mounted. If a required volume is missing, the CLI will display a warning message to help you identify and fix the issue before command execution fails.

**Log isolation:** Logs are automatically organized per command in `/data/logs` using folders named `<date>-command` (e.g., `2024-01-15-genDoc`, `2024-01-15-forweng`). This folder structure provides proper command isolation, making it easier to analyze logs for specific commands when troubleshooting issues. Each command execution creates its own log folder, allowing you to trace problems to specific operations by date and command type.

## Quick start with Docker Compose

The easiest way to use this image is with Docker Compose. We provide a `compose.yml` file that handles all the configuration.

**Important:** The [`compose.yml`](../compose.yml) file in this repository is specifically designed for the **pre-built `hackolade/hck-cli` image** and is tied to this documentation. It uses simplified data paths (`/data/*`) and the `hck-cli` binary entrypoint, which differ from compose files used with custom-built images.

### Step 1: Set Up Your Compose File

We provide a ready-to-use `compose.yml` file specifically for the pre-built image. You can either:

**Option A: Copy the provided compose file** (recommended)

Copy the [`compose.yml`](../compose.yml) file from this repository to your working directory. This compose file is specifically designed for the pre-built `hackolade/hck-cli` image and is documented in this guide:

```bash
cp compose.yml /path/to/your/working/directory/
```

**Option B: Create your own compose file**

Create a `compose.yml` file in your working directory. See the [`compose.yml`](../compose.yml) file in this repository for a complete example. Make sure to follow the structure documented in this guide.

The compose file (designed for the pre-built image) includes:
- `hck-cli` service - Main service for running CLI commands
- `showComputerIdForOfflineValidation` service - Gets computer ID for offline license validation
- `validateKeyOnline` service - Validates license online using Docker secrets
- `validateKeyOffline` service - Validates license offline using Docker secrets
- Volume definitions for app data, logs, models, and output
- Secret definitions for license key and license file

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

Create a file containing the concurrent license key you purchased for Docker. The path `${HOME}/Downloads/license-key.txt` is just an example. You can use any path you prefer, but make sure it matches the path in your `compose.yml` secrets section:

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
- **Activation Key**: Enter your concurrent license key
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

## Using Docker CLI directly

If you prefer using Docker CLI directly instead of Docker Compose, here's how:

### Basic Command Structure

```bash
docker run --rm \
  -v hackolade-studio-app-data:/home/hackolade/.config \
  -v hackolade-studio-logs:/data/logs \
  -v ${PWD}/models:/data/models \
  -v hackolade-studio-output:/data/output \
  hackolade/hck-cli:8.9.2 COMMAND [OPTIONS]
```

### Create Required Volumes

First, create the named volumes:

```bash
docker volume create hackolade-studio-app-data
docker volume create hackolade-studio-logs
docker volume create hackolade-studio-output
```

### Example Commands

**Check version:**
```bash
docker run --rm \
  -v hackolade-studio-app-data:/home/hackolade/.config \
  hackolade/hck-cli:8.9.2 version
```

**Get computer ID:**
```bash
docker run --rm hackolade/hck-cli:8.9.2 getComputerId
```

**Generate documentation:**
```bash
docker run --rm \
  -v hackolade-studio-app-data:/home/hackolade/.config \
  -v hackolade-studio-logs:/data/logs \
  -v ${PWD}/models:/data/models \
  -v hackolade-studio-output:/data/output \
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

**Note:** The container runs as user `hackolade` with UID 1000 and GID 1001 (data-modelers group).

**Note:** Docker named volumes (like `hackolade-studio-app-data`) don't require permission changes on the host.

### Volume Not Found

If Docker says a volume doesn't exist, create it:

```bash
docker volume create hackolade-studio-app-data
docker volume create hackolade-studio-logs
docker volume create hackolade-studio-output
```

Or let Docker Compose create them automatically on first run.

### Volume Validation Warnings

The CLI automatically checks for required volumes and will warn you if they're not properly mounted. If you see warnings about missing volumes:

1. **Check your compose.yml or docker run command** - Ensure all required volumes are defined:
   - `hackolade-studio-app-data` → `/home/hackolade/.config` ⚠️ **MANDATORY** - Required for licensing and configuration
   - `hackolade-studio-logs` → `/data/logs` (recommended for log isolation)
   - `hackolade-studio-output` → `/data/output` (required for output operations)

2. **Verify volumes exist:**
   ```bash
   docker volume ls | grep hackolade-studio
   ```

3. **Check volume mounts in running containers:**
   ```bash
   docker inspect <container-name> | grep -A 10 Mounts
   ```

4. **Review the warning message** - The CLI will indicate which specific volume is missing and what it's used for.

**Important:** The `/home/hackolade/.config` volume is **MANDATORY** and must be mounted for the CLI to function. While the CLI will warn about missing volumes, operations will fail without the application data volume. For proper functionality and log isolation, mount all volumes as shown in the compose examples.

### License Validation Failed

- Make sure you're using the same image tag for getting UUID and validating
- Check that you're using a concurrent license key (not a workstation license)
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
docker volume create hackolade-studio-app-data
docker volume create hackolade-studio-logs
docker volume create hackolade-studio-output

# Run command
docker run --rm \
  -v hackolade-studio-app-data:/home/hackolade/.config \
  -v hackolade-studio-logs:/data/logs \
  -v ${PWD}/models:/data/models \
  -v hackolade-studio-output:/data/output \
  hackolade/hck-cli:8.9.2 COMMAND
```

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
