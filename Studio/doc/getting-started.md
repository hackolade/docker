# Getting Started with Hackolade Studio CLI in Docker

This guide will help you run Hackolade Studio CLI in Docker, whether you're new to Docker or an experienced user. We provide instructions using both **Docker CLI directly** and **Docker Compose**. Choose the approach that works best for you.

## What is Docker? (A simple explanation)

Think of Docker as a way to package an application with everything it needs to run (like a shipping container). Instead of installing Hackolade Studio directly on your computer, you run it inside a "container", an isolated environment that has all the necessary components pre-installed.

**Key Docker concepts:**
- **Image**: A template/blueprint for creating containers (like a recipe)
- **Container**: A running instance of an image (like a meal made from the recipe)
- **Volume**: A way to store data that persists even after a container stops (like external storage)
- **Bind Mount**: Connecting a folder on your computer to a folder inside the container (like a shared folder)

## What is Docker Compose?

Docker Compose is a tool that lets you define and run multiple containers using a simple configuration file (`docker-compose.yml`). Instead of typing long Docker commands, you write the configuration once and use shorter commands.

**When to use Docker CLI directly:**
- You want to understand exactly what's happening
- You prefer explicit commands
- You're learning Docker
- You need more control over individual steps

**When to use Docker Compose:**
- You want simpler, shorter commands
- You're running the same setup repeatedly
- You prefer configuration files over long command lines
- You're working in a team (easier to share configuration)

### Compose File for custom-built images

This guide uses [`docker-compose.yml`](../docker-compose.yml), which is specifically designed for **custom-built images** based on `hackolade/studio`. This compose file:
- Uses traditional data paths (`/home/hackolade/Documents/*`)
- References your custom-built image tag (`hackolade:latest`)
- Uses the `startup.sh` entrypoint
- Is documented in this guide

**Note:** If you want to use the pre-built `hackolade/hck-cli` image instead, use [`compose.yml`](../compose.yml) which is designed for the pre-built image. See [getting-started-hck-cli.md](./getting-started-hck-cli.md) for details.

## Building your own vs. pre-built image

Before you start, decide which approach fits your needs:

| Feature | Building Your Own (`hackolade/studio`) | Pre-built Image (`hackolade/hck-cli`) |
|---------|----------------------------------------|--------------------------------------|
| Setup time | Requires build step | Instant (just pull) |
| Data paths | `/home/hackolade/Documents/*` | `/data/*` (simplified) |
| Entrypoint | `startup.sh` script | `hck-cli` binary |
| Updates | Rebuild image | Pull new version |
| Plugins | Select during build | All included |
| Architecture support | AMD64/x86_64 only (Intel-based chips) | Multi-arch (AMD64 + ARM64) |
| Customization | Full control | Limited |

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

**📖 Ready-to-use pre-built image?** See the [Getting Started Guide for the Pre-built CLI Image](./getting-started-hck-cli.md) for complete instructions.

**🔨 Need to build your own?** Continue with this guide to learn how to build a custom image with selected plugins.

## ⚠️ Migration notice for existing users

If you are currently using a custom-built image based on `hackolade/studio` and have an existing `docker-compose.yml` file, **you must migrate to the new `compose.yml` structure** when using the pre-built `hackolade/hck-cli` image.

**Key differences you need to update:**

1. **Image reference**: Change from your custom image tag to `hackolade/hck-cli:8.12.7` (or appropriate version)
2. **Data paths**: Update volume mounts from `/home/hackolade/Documents/*` to `/data/*`
   - `/home/hackolade/Documents/models` → `/data/models`
   - `/home/hackolade/Documents/output` → `/data/output`
   - `/home/hackolade/Documents/HackoladeLogs` → `/data/logs`
3. **Entrypoint**: The pre-built image uses `hck-cli` binary directly (no `startup.sh` wrapper needed)
4. **Working directory**: Remove `-w /home/hackolade/Documents` as it's no longer needed

**Reference compose file:** Use the [`compose.yml`](../compose.yml) file in this repository as your migration reference. This compose file is specifically designed for the pre-built image and documented in [getting-started-hck-cli.md](./getting-started-hck-cli.md).

**If you continue building your own image:** Use the [`docker-compose.yml`](../docker-compose.yml) file in this repository, which is specifically designed for custom-built images. This compose file uses the traditional data paths (`/home/hackolade/Documents/*`) and is documented in this guide.

## Prerequisites

Before you begin, make sure you have:
1. **Docker installed** on your system ([Install Docker](https://www.docker.com/get-started))
2. **Docker is running** (check by running `docker --version` in your terminal)
3. A **floating Hackolade license key** (required for Docker CLI usage -- a.k.a. concurrent license key)




## Step 1: Understanding data storage

Hackolade needs to store and access data. We use **volumes** to make data persist between container runs.

### Required storage locations

Inside the container, Hackolade uses these folders:
- `/home/hackolade/.config/Hackolade` : Application data (settings, license info)
- `/home/hackolade/Documents/HackoladeLogs` : Log files
- `/home/hackolade/Documents/output` : Generated files (documentation, schemas, etc.)
- `/home/hackolade/Documents/models` : Your model files (input)

**Important notes on folder customization:**

- **`models` and `output` folders**: These are the **only folders that can be customized** and mounted anywhere in the container (not just `/home/hackolade/Documents/models` and `/home/hackolade/Documents/output`), as long as you adapt the command options to match your custom location. However, the image is preconfigured to work from `/home/hackolade/Documents`, so using the default locations simplifies your commands.

- **`HackoladeLogs` folder**: Can be bind mounted from the host as long as the folder has the correct permissions (UID 1000, GID 0). However, using a Docker named volume is recommended for simplicity.

- **Application data (`/home/hackolade/.config/Hackolade`)**: **Cannot be moved** and bind mounting it can create unexpected issues. It's safer to keep it in a Docker named volume (which is the default in our examples).

### Setting up storage: Docker CLI method

With Docker CLI, you'll create **named volumes** (Docker-managed storage) and **bind mounts** (folders on your computer).

**Create named volumes:**
```bash
docker volume create hackolade-studio-app-data
docker volume create hackolade-studio-logs
docker volume create hackolade-studio-output
```

**Create a folder on your computer for models:**
```bash
mkdir -p ./models
chown -R 1000:0 ./models
```

**Why `chown 1000:0`?** The container runs as user `hackolade` with UID 1000 and GID 0. This command ensures the folder is writable by the container.

### Setting up storage: Docker Compose method

Docker Compose automatically creates volumes when you first run it. You just need to create the models folder:

```bash
mkdir -p ./models
chown -R 1000:0 ./models
```

The [`docker-compose.yml`](../docker-compose.yml) file (already in this repository) is specifically designed for custom-built images and defines all the volumes for you.




## Step 2: Building the Docker image

First, you need to build a Docker image that contains Hackolade Studio.

### Docker CLI method

```bash
docker build --no-cache --pull -t hackolade:latest .
```

**What this does:**
- `docker build` - Builds a Docker image
- `--no-cache` - Ensures a fresh build (ignores cached layers)
- `--pull` - Downloads the latest base image
- `-t hackolade:latest` - Tags the image with name "hackolade" and version "latest"
- `.` - Uses the Dockerfile in the current directory

### Docker Compose method

Docker Compose doesn't build images directly, but you can still use the same Docker CLI command:

```bash
docker build --no-cache --pull -t hackolade:latest .
```

**Note:** The [`docker-compose.yml`](../docker-compose.yml) file (designed for custom-built images) references `hackolade:latest`, so make sure your image has this exact tag.



## Step 3: Validating your license

Before you can use Hackolade CLI, you must validate your license key for the Docker image.

### Docker CLI method

**Step 3a: Get the computer ID**
```bash
docker run --rm \
  --entrypoint show-computer-id.sh \
  hackolade:latest
```

This will output a UUID (like `12345678-1234-1234-1234-123456789abc`). Copy this value.

**Step 3b: Validate the license (Online)**
```bash
docker run --rm \
  -v hackolade-studio-app-data:/home/hackolade/.config/Hackolade \
  hackolade:latest validatekey \
  --key=YOUR-LICENSE-KEY \
  --identifier=YOUR-UUID-FROM-STEP-3A
```

Replace:
- `YOUR-LICENSE-KEY` with your actual license key
- `YOUR-UUID-FROM-STEP-3A` with the UUID from step 3a

**What this does:**
- `docker run --rm` - Runs a container and removes it when done
- `-v hackolade-studio-app-data:/home/hackolade/.config/Hackolade` - Mounts the volume where license data is stored
- `hackolade:latest` - Uses the image you built
- `validatekey` - The Hackolade CLI command to validate a license

**Step 3c: Validate the license (Offline)**

For offline validation, see the detailed instructions in [license-validation.md](./license-validation.md).

### Docker Compose method

**Step 3a: Get the computer ID**
```bash
docker compose run --rm --entrypoint show-computer-id.sh hackoladeStudioCLI
```

**Step 3b: Validate the license (Online)**
```bash
docker compose run --rm hackoladeStudioCLI validatekey \
  --key=YOUR-LICENSE-KEY \
  --identifier=$(docker compose run --rm --entrypoint show-computer-id.sh hackoladeStudioCLI)
```

This single command does both steps automatically by using `$(...)` to get the UUID inline.

**Note:** The [`docker-compose.yml`](../docker-compose.yml) file (designed for custom-built images) automatically handles all the volume mounts, so you don't need to specify them manually.



## Step 4: Running Hackolade CLI commands

Now you're ready to run Hackolade CLI commands!

### Docker CLI method

**Basic command structure:**
```bash
docker run --rm \
  -v hackolade-studio-app-data:/home/hackolade/.config/Hackolade \
  -v hackolade-studio-logs:/home/hackolade/Documents/HackoladeLogs \
  -v hackolade-studio-output:/home/hackolade/Documents/output \
  -v ${PWD}/models:/home/hackolade/Documents/models \
  -w /home/hackolade/Documents \
  hackolade:latest COMMAND [OPTIONS]
```

**What each part does:**
- `docker run --rm` : Run container and remove when done
- `-v hackolade-studio-app-data:...` : Mount app data volume
- `-v hackolade-studio-logs:...` : Mount logs volume
- `-v hackolade-studio-output:...` : Mount output volume
- `-v ${PWD}/models:...` : Mount your local models folder
- `-w /home/hackolade/Documents` : Set working directory
- `hackolade:latest` : The image to use
- `COMMAND [OPTIONS]` : The Hackolade CLI command

**Example: Show help**
```bash
docker run --rm \
  -v hackolade-studio-app-data:/home/hackolade/.config/Hackolade \
  -v hackolade-studio-logs:/home/hackolade/Documents/HackoladeLogs \
  -v hackolade-studio-output:/home/hackolade/Documents/output \
  -v ${PWD}/models:/home/hackolade/Documents/models \
  -w /home/hackolade/Documents \
  hackolade:latest help
```

**Example: Check version**
```bash
docker run --rm \
  -v hackolade-studio-app-data:/home/hackolade/.config/Hackolade \
  -v hackolade-studio-logs:/home/hackolade/Documents/HackoladeLogs \
  -v hackolade-studio-output:/home/hackolade/Documents/output \
  -v ${PWD}/models:/home/hackolade/Documents/models \
  -w /home/hackolade/Documents \
  hackolade:latest version
```

### Docker Compose Method

**Basic command structure:**
```bash
docker compose run --rm hackoladeStudioCLI COMMAND [OPTIONS]
```

Much simpler! Docker Compose automatically handles all the volumes based on [`docker-compose.yml`](../docker-compose.yml), which is designed for custom-built images.

**Example: Show help**
```bash
docker compose run --rm hackoladeStudioCLI help
```

**Example: Check version**
```bash
docker compose run --rm hackoladeStudioCLI version
```



## Step 5: Common scenarios

### Scenario 1: Generate documentation

Generate HTML documentation from a model file.

**Docker CLI Method:**
```bash
docker run --rm \
  -v hackolade-studio-app-data:/home/hackolade/.config/Hackolade \
  -v hackolade-studio-logs:/home/hackolade/Documents/HackoladeLogs \
  -v hackolade-studio-output:/home/hackolade/Documents/output \
  -v ${PWD}/models:/home/hackolade/Documents/models \
  -w /home/hackolade/Documents \
  hackolade:latest genDoc \
  --model=/home/hackolade/Documents/models/model.json \
  --format=HTML \
  --doc=/home/hackolade/Documents/output/doc.html
```

**Docker Compose Method:**
```bash
docker compose run --rm hackoladeStudioCLI genDoc \
  --model=/home/hackolade/Documents/models/model.json \
  --format=HTML \
  --doc=/home/hackolade/Documents/output/doc.html
```

### Scenario 2: Forward engineering

Generate JSON Schema files from a model.

**Docker CLI Method:**
```bash
docker run --rm \
  -v hackolade-studio-app-data:/home/hackolade/.config/Hackolade \
  -v hackolade-studio-logs:/home/hackolade/Documents/HackoladeLogs \
  -v hackolade-studio-output:/home/hackolade/Documents/output \
  -v ${PWD}/models:/home/hackolade/Documents/models \
  -w /home/hackolade/Documents \
  hackolade:latest forweng \
  --model=/home/hackolade/Documents/models/model.json \
  --jsonschemacompliance=full \
  --skipUndefinedLevel \
  --structuredpath=false \
  --path=/home/hackolade/Documents/output/ \
  --outputtype=jsonschema
```

**Docker Compose Method:**
```bash
docker compose run --rm hackoladeStudioCLI forweng \
  --model=/home/hackolade/Documents/models/model.json \
  --jsonschemacompliance=full \
  --skipUndefinedLevel \
  --structuredpath=false \
  --path=/home/hackolade/Documents/output/ \
  --outputtype=jsonschema
```

### Scenario 3: Reverse engineering

Reverse engineer a database to create a model.

**Docker CLI Method:**
```bash
docker run --rm \
  -v hackolade-studio-app-data:/home/hackolade/.config/Hackolade \
  -v hackolade-studio-logs:/home/hackolade/Documents/HackoladeLogs \
  -v hackolade-studio-output:/home/hackolade/Documents/output \
  -v ${PWD}/models:/home/hackolade/Documents/models \
  -w /home/hackolade/Documents \
  hackolade:latest revEng \
  --target=MONGODB \
  --connectFile=/home/hackolade/Documents/models/connection.bin \
  --model=/home/hackolade/Documents/models/output-model.json \
  --selectedObjects="database_name" \
  --inferRelationships=true
```

**Docker Compose Method:**
```bash
docker compose run --rm hackoladeStudioCLI revEng \
  --target=MONGODB \
  --connectFile=/home/hackolade/Documents/models/connection.bin \
  --model=/home/hackolade/Documents/models/output-model.json \
  --selectedObjects="database_name" \
  --inferRelationships=true
```

### Scenario 4: Compare two models

Compare two model files and generate a delta model.

**Docker CLI Method:**
```bash
docker run --rm \
  -v hackolade-studio-app-data:/home/hackolade/.config/Hackolade \
  -v hackolade-studio-logs:/home/hackolade/Documents/HackoladeLogs \
  -v hackolade-studio-output:/home/hackolade/Documents/output \
  -v ${PWD}/models:/home/hackolade/Documents/models \
  -w /home/hackolade/Documents \
  hackolade:latest compMod \
  --model1=/home/hackolade/Documents/models/model1.json \
  --model2=/home/hackolade/Documents/models/model2.json \
  --deltamodel=/home/hackolade/Documents/output/delta.json
```

**Docker Compose Method:**
```bash
docker compose run --rm hackoladeStudioCLI compMod \
  --model1=/home/hackolade/Documents/models/model1.json \
  --model2=/home/hackolade/Documents/models/model2.json \
  --deltamodel=/home/hackolade/Documents/output/delta.json
```



## Step 6: Retrieving generated files

After running commands, you need to copy files from Docker volumes to your computer.

### Docker CLI method

**Retrieve output files:**
```bash
docker run --rm --init \
  --name hackolade-data-extractor \
  -u root \
  -v hackolade-studio-output:/output \
  -v ${PWD}/output:/output-on-host \
  --entrypoint cp \
  hackolade:latest -r /output /output-on-host/.
```

**Retrieve log files:**
```bash
docker run --rm --init \
  --name hackolade-log-extractor \
  -u root \
  -v hackolade-studio-logs:/logs \
  -v ${PWD}/logs:/logs-on-host \
  --entrypoint cp \
  hackolade:latest -r /logs /logs-on-host/.
```

**What this does:**
- Creates a temporary container as root user
- Mounts the Docker volume and a local folder
- Uses `cp` command to copy files from volume to local folder
- Removes container when done (`--rm`)

### Docker Compose method

Docker Compose doesn't have a built-in way to extract files, so you still use Docker CLI:

```bash
# Retrieve output files
docker run --rm --init \
  --name hackolade-data-extractor \
  -u root \
  -v hackolade-studio-output:/output \
  -v ${PWD}/output:/output-on-host \
  --entrypoint cp \
  hackolade:latest -r /output /output-on-host/.

# Retrieve log files
docker run --rm --init \
  --name hackolade-log-extractor \
  -u root \
  -v hackolade-studio-logs:/logs \
  -v ${PWD}/logs:/logs-on-host \
  --entrypoint cp \
  hackolade:latest -r /logs /logs-on-host/.
```



## Creating a helper script (optional)

To make Docker CLI commands easier, you can create a helper script.

**Create `run-hackolade.sh`:**
```bash
#!/bin/bash
docker run --rm \
  -v hackolade-studio-app-data:/home/hackolade/.config/Hackolade \
  -v hackolade-studio-logs:/home/hackolade/Documents/HackoladeLogs \
  -v hackolade-studio-output:/home/hackolade/Documents/output \
  -v ${PWD}/models:/home/hackolade/Documents/models \
  -w /home/hackolade/Documents \
  hackolade:latest "$@"
```

**Make it executable:**
```bash
chmod +x run-hackolade.sh
```

**Now you can use it like:**
```bash
./run-hackolade.sh help
./run-hackolade.sh genDoc --model=/home/hackolade/Documents/models/model.json --format=HTML --doc=/home/hackolade/Documents/output/doc.html
```



## Troubleshooting

### Permission denied Errors

**Note:** This only applies to **bind mounts** (folders on your host computer), not to Docker named volumes.

If you get permission errors with bind-mounted folders (like `./models`), make sure they have correct permissions:
```bash
chown -R 1000:0 ./models
chown -R 1000:0 ./output
chown -R 1000:0 ./logs
```

**Note:** This only applies to bind-mounted folders. Docker named volumes (like `hackolade-studio-app-data`, `hackolade-studio-logs`, `hackolade-studio-output`) are managed by Docker and don't require permission changes on the host. For more information on which folders can be customized, see the [Required Storage Locations](#required-storage-locations) section above.

### Volume Not Found

If Docker says a volume doesn't exist, create it:
```bash
docker volume create hackolade-studio-app-data
docker volume create hackolade-studio-logs
docker volume create hackolade-studio-output
```

### License Validation Failed

- Make sure you're using the same image for getting UUID and validating
- Check that you're using a floating license key (not a workstation license)
- Ensure the license has available seats



## Next Steps

- Read [build.md](./build.md) for building custom images with plugins
- Read [license-validation.md](./license-validation.md) for detailed license validation instructions
- Read [interactive-sessions.md](./interactive-sessions.md) to learn how to use the Docker image interactively for development and debugging
- Check the [Hackolade CLI documentation](https://hackolade.com/help/CommandLineInterface.html) for all available commands



## Quick reference

### Docker CLI quick commands

```bash
# Build image
docker build --no-cache --pull -t hackolade:latest .

# Create volumes
docker volume create hackolade-studio-app-data
docker volume create hackolade-studio-logs
docker volume create hackolade-studio-output

# Run command
docker run --rm \
  -v hackolade-studio-app-data:/home/hackolade/.config/Hackolade \
  -v hackolade-studio-logs:/home/hackolade/Documents/HackoladeLogs \
  -v hackolade-studio-output:/home/hackolade/Documents/output \
  -v ${PWD}/models:/home/hackolade/Documents/models \
  -w /home/hackolade/Documents \
  hackolade:latest COMMAND
```

### Docker Compose quick commands

```bash
# Build image (same as Docker CLI)
docker build --no-cache --pull -t hackolade:latest .

# Run command
docker compose run --rm hackoladeStudioCLI COMMAND
```
