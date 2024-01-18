# Running Hackolade Studio CLI in Docker 

![Docker Image Version (latest by date)](https://img.shields.io/docker/v/hackolade/studio)

The instructions below assume that you have Docker [installed](https://www.docker.com/get-started) and running.

The purpose of running Hackolade Studio in a Docker container is to operate the Command-Line Interface ("CLI"), typically in a the context of integration with CI/CD pipelines.  

⚠ It is **not** to run the application GUI, which is **not** supported.

## Repository structure
This repository contains files and instructions for running [Hackolade](https://hackolade.com) applications published on [Docker Hub](https://hub.docker.com/r/hackolade/studio):

- [Dockerfile](Dockerfile): ready-to-use example of a full installation of Hackolade Studio, including the possibility to install selected target plugins
- [docker-compose.yml](docker-compose.yml): example of how the recommended way to configure the launch of containers of the Hackolade CLI.
- [securityPolicies.json](securityPolicies.json) - [optional] the list of required system call operations to be able to run Hackolade with Chrome sandboxing (disabled by default) inside a container ([more details](https://docs.docker.com/engine/security/seccomp/))
- batch files examples when running on Windows:
  - [docker-help.bat](docker-help.bat): verify the proper running of the CLI by displaying the CLI help in a container.  Will work without a validated license key.
  - [docker-validateKey.bat](docker-validateKey.bat): validate a license key
  - [docker-genDoc.bat](docker-genDoc.bat): run the CLI for the genDoc command.  Requires a validated license key.

## Licensing

**Important note:**  the Docker CLI requires a **concurrent** license key with an **available seat**.   If the seat gets validated offline, it remains dedicated to the Docker CLI and is not sharable with other users.  To ensure that your CI/CD pipeline jobs always have an available seat, you may want to get a concurrent license key dedicated to this purpose.  On a single machine, you may run multiple containers of the same image in parallel with a concurrent license key.    An individual workstation license of Hackolade is **not** sufficient.  If you just need to run the CLI from an OS command prompt or terminal, you may do so with your regular Professional or Workgroup edition license.

To purchase a concurrent license subscription, please send an email to support@hackolade.com. 

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
Hackolade reads and writes data to the following folders inside containers:

-**/home/hackolade/.config/Hackolade**: this folder (**appData**) is necessary for the proper operation of the application in containers and must be readable and writable by **hackolade** user.
-**/home/hackolade/Documents/HackoladeLogs**: this folder is where Hackolade Studio writes its logging information, which is useful in case of any issue and must be readable and writable by **hackolade** user.
- **/home/hackolade/Documents/data**: we recommend this folder that will be used for generated artifacts within containers but you can define it anywhere inside container filesystem as long as you make it persistent.  It may contain models, documentation, sources for reverse-engineering, artifacts out of forward-engineering, etc...  Instead of a relative path to the location where the container is run, you may reference an absolute path to the location of these files.
-[Optional]**/home/hackolade/.hackolade/options**: is where Hackolade reads user defined configurations like naming conventions, excel export options, custom properties, etc...


You must create manually the folders you will bind mount prior to running hackolade studio containers because docker doesn't create them automatically anymore.

#### File permissions and bind mounts
Any pre-existing data in the Docker image in the bind mounted folders will be **erased and overridde**n** by the data present on the host folder.  Docker will use the user owning the folder on the host as the owner of all the files of target directory where the bind mount is done.  Therefore, the unprivileged **hackolade** user inside the container (note that Hackolade CLI can not be run as *root***) must have enough permissions to write and read from these host folders.  


##### Example how to set permissions on host folder

```bash
mkdir -p $PWD/models $PWD/hackolade-options
chown -R 1000:0 $PWD/models $PWD/hackolade-options
```

## Build the image

The first required step is to build the Docker image with the Hackolade Studio application and the plugins you want to use.  Follow instructions details in [this page](./doc/build.md).

Once you have built the Docker image you will need to first validate your concurrent license for that new image before being able to run the Hackolade CLI with your scenario of choice.

### Validate license key for the image

Follow the fully detailed instructions in [this page](./doc/license-validation.md).

**Note:** The license key validation must be repeated for each new Docker image.


## Run Hackolade CLI in a container

It is suggested to run commands using the [docker-compose.yml](docker-compose.yml) file, possibly after editing it for your specific needs. 

A typical command will look like this:

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

You may consult our [online documentation](https://hackolade.com/help/CommandLineInterface.html) for the full description of commands and their respective arguments.


## Example Scenario: Generate documentation and forward engineer for a model

This example is using the [docker-compose.yml](./docker-compose.yml) file. 

Assuming that a valid Hackolade model file called *`model.json`* is placed in the *`models`* subfolder of the location where the container is being run:

1. Build the docker image with **hackolade:latest** tag:
    ```bash
    docker build --no-cache --pull -t hackolade:latest .
    ```
2. Validate the license (online)
    ```bash
    docker compose run --rm hackoladeStudioCLI validatekey \
            --key=<concurrent-license-key> \
            --identifier=$(docker compose run --rm --entrypoint show-computer-id.sh hackoladeStudioCLI)
    ```
3. Generate documentation for the model.json file
    ```bash
    docker compose run --rm hackoladeStudioCLI genDoc --model=/home/hackolade/Documents/models/model.json --format=html --doc=/home/hackolade/Documents/output/doc.html
    ```
4. Forward engineer the model in output folder
    ```bash
    docker compose run --rm hackoladeStudioCLI forweng \
        --model model.json \
        --jsonschemacompliance full \
        --skipUndefinedLevel \
        --structuredpath false \
        --path /home/hackolade/Documents/output/ \
        --outputtype jsonschema
    ```
5. Retrieve Hackolade logs from the **hackolade-studio-output** docker volume:
    ```bash
    docker run --rm --init \
        --name hackolade-data-extractor \
        -u root \
        -v hackolade-studio-output:/output \
        -v ./output:/output-on-host \
        --entrypoint cp \
      hackolade:latest -r /output /output-on-host/. 
    ```

6. Retrieve generated files from the **hackolade-studio-logs** docker volume:
    ```bash
      docker run --rm --init \
        --name hackolade-data-extractor \
        -u root \
        -v hackolade-studio-logs:/logs \
        -v ./logs:/logs-on-host \
        --entrypoint cp \
      hackolade:latest -r /logs /logs-on-host/. 
    ```

This example can be adjusted to run any CLI command, as documented [here](https://hackolade.com/help/CommandLineInterface.html).


### Custom properties, naming conventions, Excel export options

You may have customized the behavior of the application GUI, and wish to use them during CLI processing.  

If the containers will be running on a machine with no Hackolade Studio GUI, you use in the [docker-compose.yml](docker-compose.yml) file the default subfolder of the location where the containers will be running:

         - ./options:/home/hackolade/.hackolade/options

Or you may reference an absolute path to the location of these files, if you're also running the Hackolade Studio GUI on the same Windows machine:

```Windows
     - C:/Users/%username%/.hackolade/options:/home/hackolade/.hackolade/options
```
