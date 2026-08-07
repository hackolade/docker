# Running Hackolade Studio CLI in Docker

![Docker Image Version (latest by date)](https://img.shields.io/docker/v/hackolade/hck-cli)

The purpose of running Hackolade in a Docker container is to operate the **Command-Line Interface (CLI)**, typically in CI/CD pipelines.

⚠ The purpose is **not** to run the application GUI in Docker — this is **not** supported.

The instructions below assume Docker is [installed](https://www.docker.com/get-started) and running.

## 🚀 Getting started (recommended)

Use the pre-built [`hackolade/hck-cli`](https://hub.docker.com/r/hackolade/hck-cli/tags) image — Hackolade Studio CLI with all plugins, no build step:

**[Getting started with hackolade/hck-cli](./doc/getting-started-hck-cli.md)** — consolidated writes to `/data` + `/tmp`, hardened Compose, and Kubernetes examples.

```bash
# Recommended baseline for CI / production (read-only rootfs, same write layout)
docker compose -f compose.hardened.yml run --rm hck-cli version
```

## Runtime model

Every `hackolade/hck-cli` deployment uses **two writable mounts only**:

| Mount | Purpose |
| --- | --- |
| `/data` | License state, models, output, logs (persistent volume or PVC) |
| `/tmp` | Sockets, caches, scratch (tmpfs / memory emptyDir) |

[`compose.yml`](./compose.yml) and [`compose.hardened.yml`](./compose.hardened.yml) share this layout. Hardened adds read-only root filesystem, dropped capabilities, and non-root execution — the profile used in [`k8s/`](./k8s/) as well.

## Build your own image (advanced)

Need a custom plugin set or Dockerfile based on [`hackolade/studio`](https://hub.docker.com/r/hackolade/studio/tags)? See [getting-started.md](./doc/getting-started.md) and [build.md](./doc/build.md).

## Repository structure

Primary examples use the pre-built **`hackolade/hck-cli`** image (same `/data` + `/tmp` write layout in every profile):

- [compose.yml](compose.yml): local Compose — consolidated mounts, writable rootfs
- [compose.hardened.yml](compose.hardened.yml): **hardened** — same mounts + read-only rootfs, `cap_drop: ALL`
- [k8s/](k8s/): **Kubernetes** Jobs — same mounts + Restricted Pod Security Standard

Custom-build path (legacy layout on `hackolade/studio`):

- [Dockerfile](Dockerfile): example full installation with selected plugins
- [docker-compose.yml](docker-compose.yml): Compose for custom-built images
- [securityPolicies.json](securityPolicies.json) - [optional] the list of required system call operations to be able to run Hackolade with Chrome sandboxing (disabled by default) inside a container ([more details](https://docs.docker.com/engine/security/seccomp/))
- batch files examples when running on Windows:
  - [docker-help.bat](docker-help.bat): verify the proper running of the CLI by displaying the CLI help in a container.  Will work without a validated license key.
  - [docker-validateKey.bat](docker-validateKey.bat): validate a license key
  - [docker-genDoc.bat](docker-genDoc.bat): run the CLI for the genDoc command.  Requires a validated license key.



## Licensing

**Important note:**  the Docker CLI requires a **floating** (a.k.a. concurrent) license key with an **available seat**.   If the seat gets validated offline, it remains dedicated to the Docker CLI and is not sharable with other users.  To ensure that your CI/CD pipeline jobs always have an available seat, you may want to get a floating license key dedicated to this purpose.  On a single machine, you may run multiple containers of the same image in parallel with a floating license key.    An individual workstation license of Hackolade is **not** sufficient.  If you just need to run the CLI from an OS command prompt or terminal, you may do so with your regular Professional or Workgroup edition license.

To purchase a floating license subscription, please send an email to support@hackolade.com.

To ensure proper behavior of the Hackolade Studio CLI in a Docker container, make sure to use an Hackolade version v5.1.1 or above.



## Managing data

Hackolade requires to read and persist data from some specific folders.  There are many ways to manage data in the context of containers using [data volumes](https://docs.docker.com/storage/volumes/).

For security reasons and following best practices for running containers, Hackolade will run using a dedicated yet **unprivileged** user: **hackolade**.

For portability reasons, we advise to use Docker named volumes for folders where Hackolade is writing as much as possible instead of bind mounts from the host.  It deeply simplifies the requirements for running Hackolade Docker image.  This is especially true for the two operational folders **appData** and **HackoladeLogs** as well as for the folder Hackolade will generate output artifacts, like results of forward engineering commands.

In general, reading data out of any folder should likely work out of the box because our **hackolade** user is having **GID 0**, but for writing data the target folder should be writable by our **hackolade** user.

We advise to separate input folders (read by Hackolade Studio) from output folders to simplify operations.

### hackolade user inside containers
The **hackolade** user pre-configured inside the image has the following UID/GID that you can use to properly configure the folders and files permissions on the host:

- UID: 1000
- GID: 0



### Required directories (inside containers)

#### Pre-built `hackolade/hck-cli` image (recommended)

The image expects a **read-only root filesystem** with exactly two writable mounts:

- **`/data`** (persistent volume): license/userData under `/data/app`, plus logs, models, output, settings, and options
- **`/tmp`** (tmpfs): sockets, caches, and scratch files

See [`doc/getting-started-hck-cli.md`](./doc/getting-started-hck-cli.md) and [`compose.yml`](./compose.yml). Custom CAs use read-only PEM mounts and `NODE_EXTRA_CA_CERTS` / `SSL_CERT_FILE` — see [`doc/custom-certificates.md`](./doc/custom-certificates.md).

For hardened deployments, see [`compose.hardened.yml`](./compose.hardened.yml) and [`k8s/`](./k8s/).

**Breaking change:** do not mount `/home/hackolade/.config` for the pre-built image; that path is no longer used for license state.

#### Custom-built `hackolade/studio` images

Older custom builds may still use the historical layout:

- `/home/hackolade/.config/Hackolade`: application data (**appData**) — must be readable and writable by the container user
- `/home/hackolade/Documents/HackoladeLogs`: logging information
- `/home/hackolade/Documents/data`: generated artifacts (models, documentation, RE/FE outputs, etc.)
- [Optional] `/home/hackolade/.hackolade/options`: user-defined configurations

Prefer migrating custom images to the `/data` + `/tmp` model used by `hackolade/hck-cli`.


You must create manually the folders you will bind mount prior to running hackolade studio containers because docker doesn't create them automatically anymore.

#### File permissions and bind mounts

Any pre-existing data in the Docker image in the bind mounted folders will be **erased and overridde**n** by the data present on the host folder.  Docker will use the user owning the folder on the host as the owner of all the files of target directory where the bind mount is done.  Therefore, the unprivileged **hackolade** user inside the container (note that Hackolade CLI can not be run as *root***) must have enough permissions to write and read from these host folders.


##### Example how to set permissions on host folder

```bash
mkdir -p $PWD/models $PWD/hackolade-options
chown -R 1000:0 $PWD/models $PWD/hackolade-options
```



## Build the image

The very first step is to fetch the base image from our [Docker Hub latest tag](https://hub.docker.com/r/hackolade/studio/tags).

Then you must build your Docker image with the Hackolade Studio application version and the plugins that you want to use.  Follow instructions details in [this page](./doc/build.md).

Once you have built the Docker image you need to first validate your floating license for that new image before being able to run the Hackolade CLI with your scenario of choice.

### Validate license key for the image

Follow the fully detailed instructions in [this page](./doc/license-validation.md).

**Note:** The license key validation must be repeated for each new Docker image.



## Run Hackolade CLI in a container

You can run Hackolade CLI commands using either **Docker CLI directly** or **Docker Compose**. Both approaches are fully supported and documented.

### Using Docker Compose (Recommended for simplicity)

Docker Compose uses the [docker-compose.yml](docker-compose.yml) file to manage volumes and configuration automatically, resulting in shorter commands.

A typical command:
```bash
docker compose run --rm hackoladeStudioCLI command [--arguments]
```

where:
- `hackoladeStudioCLI` is the name of the service as defined in docker-compose.yml
- `command` is the CLI command
- `--arguments` is for optional arguments

Example:
```bash
docker compose run --rm hackoladeStudioCLI help
```

### Using Docker CLI Directly

If you prefer explicit control or want to understand exactly what's happening, you can use Docker CLI commands directly:

```bash
docker run --rm \
  -v hackolade-studio-app-data:/home/hackolade/.config/Hackolade \
  -v hackolade-studio-logs:/home/hackolade/Documents/HackoladeLogs \
  -v hackolade-studio-output:/home/hackolade/Documents/output \
  -v ${PWD}/models:/home/hackolade/Documents/models \
  -w /home/hackolade/Documents \
  hackolade:latest command [--arguments]
```

Example:
```bash
docker run --rm \
  -v hackolade-studio-app-data:/home/hackolade/.config/Hackolade \
  -v hackolade-studio-logs:/home/hackolade/Documents/HackoladeLogs \
  -v hackolade-studio-output:/home/hackolade/Documents/output \
  -v ${PWD}/models:/home/hackolade/Documents/models \
  -w /home/hackolade/Documents \
  hackolade:latest help
```

**For detailed instructions and more examples, see the [Getting Started Guide](./doc/getting-started.md).**

You may consult our [online documentation](https://hackolade.com/help/CommandLineInterface.html) for the full description of commands and their respective arguments.



## Example Scenario: Generate documentation and forward-engineer for a model

This example shows how to generate documentation and forward-engineer a model. We provide both **Docker CLI** and **Docker Compose** versions.

Assuming that a valid Hackolade model file called *`model.json`* is placed in the *`models`* subfolder of the location where the container is being run:

### Step 1: Build the docker image

Both methods use the same build command:
```bash
docker build --no-cache --pull -t hackolade:latest .
```

### Step 2: Validate the license

**Using Docker Compose:**
```bash
docker compose run --rm hackoladeStudioCLI validatekey \
        --key=<floating-license-key> \
        --identifier=$(docker compose run --rm --entrypoint show-computer-id.sh hackoladeStudioCLI)
```

**Using Docker CLI:**
```bash
# First, get the computer ID
UUID=$(docker run --rm --entrypoint show-computer-id.sh hackolade:latest)

# Then validate the license
docker run --rm \
  -v hackolade-studio-app-data:/home/hackolade/.config/Hackolade \
  hackolade:latest validatekey \
  --key=<floating-license-key> \
  --identifier=$UUID
```

For detailed license validation instructions (including offline), see [license-validation.md](./doc/license-validation.md).

### Step 3: Generate documentation

**Using Docker Compose:**
```bash
docker compose run --rm hackoladeStudioCLI genDoc \
  --model=/home/hackolade/Documents/models/model.json \
  --format=HTML --doc=/home/hackolade/Documents/output/doc.html
```

**Using Docker CLI:**
```bash
docker run --rm \
  -v hackolade-studio-app-data:/home/hackolade/.config/Hackolade \
  -v hackolade-studio-logs:/home/hackolade/Documents/HackoladeLogs \
  -v hackolade-studio-output:/home/hackolade/Documents/output \
  -v ${PWD}/models:/home/hackolade/Documents/models \
  -w /home/hackolade/Documents \
  hackolade:latest genDoc \
  --model=/home/hackolade/Documents/models/model.json \
  --format=HTML --doc=/home/hackolade/Documents/output/doc.html
```

### Step 4: Forward engineer the model

**Using Docker Compose:**
```bash
docker compose run --rm hackoladeStudioCLI forweng \
    --model model.json \
    --jsonschemacompliance full \
    --skipUndefinedLevel \
    --structuredpath false \
    --path /home/hackolade/Documents/output/ \
    --outputtype jsonschema
```

**Using Docker CLI:**
```bash
docker run --rm \
  -v hackolade-studio-app-data:/home/hackolade/.config/Hackolade \
  -v hackolade-studio-logs:/home/hackolade/Documents/HackoladeLogs \
  -v hackolade-studio-output:/home/hackolade/Documents/output \
  -v ${PWD}/models:/home/hackolade/Documents/models \
  -w /home/hackolade/Documents \
  hackolade:latest forweng \
  --model model.json \
  --jsonschemacompliance full \
  --skipUndefinedLevel \
  --structuredpath false \
  --path /home/hackolade/Documents/output/ \
  --outputtype jsonschema
```

### Step 5: Retrieve generated files

Both methods use the same commands to extract files from Docker volumes:

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

**For more examples and detailed explanations, see the [Getting Started Guide](./doc/getting-started.md).**

This example can be adjusted to run any CLI command, as documented [here](https://hackolade.com/help/CommandLineInterface.html).


### Custom properties, naming conventions, Excel export options

You may have customized the behavior of the application GUI, and wish to use them during CLI processing.

If the containers will be running on a machine with no Hackolade Studio GUI, you use in the [docker-compose.yml](docker-compose.yml) file the default subfolder of the location where the containers will be running:

         - ${PWD}/options:/home/hackolade/.hackolade/options

Or you may reference an absolute path to the location of these files, if you're also running the Hackolade Studio GUI on the same Windows machine:

```Windows
     - C:/Users/%username%/.hackolade/options:/home/hackolade/.hackolade/options
```



## Running the CLI from GitHub Actions based on a trigger

Take a look at [this repository](https://github.com/hackolade/studio-cli-github-actions-examples) for such an illustration.
