# Running Hackolade Studio CLI in Docker 

![Docker Image Version (latest by date)](https://img.shields.io/docker/v/hackolade/studio)

The instructions below assume that you have Docker [installed](https://www.docker.com/get-started) and running.

The purpose of running Hackolade Studio in a Docker container is to operate the Command-Line Interface ("CLI"), typically in a the context of integration with CI/CD pipelines.  It is **not** to run the application GUI, a use case which has not been tested.

**Important note:**  the CLI requires a **concurrent** license key with an available seat.  An individual workstation license of Hackolade is **not** sufficient.  To ensure that your CI/CD pipeline jobs always have an available seat, you may want to get a concurrent license key dedicated to this purpose.  On a single machine, you may run multiple containers of the same image in parallel with a concurrent license key.  
To purchase a concurrent license, perpetual or subscription, please send an email to support@hackolade.com. 

To ensure proper behavior of the Hackolade Studio CLI in a Docker container, make sure to run version v5.1.1 or above.


This repository contains files and instructions for running [Hackolade](https://hackolade.com) applications published on [Docker Hub](https://hub.docker.com/r/hackolade/studio):

- [Dockerfile.app](Dockerfile.app): ready-to-use example of a full installation of Hackolade Studio, including the possibility to install selected target plugins
- [Dockerfile.plugins](Dockerfile.plugins): example of a how to install additional target plugins
- [docker-compose.yml](docker-compose.yml): example of how to configure the launch of containers of the Hackolade CLI
- [securityPolicies.json](securityPolicies.json) - [optional] the list of required system call operations to be able to run Hackolade with Chrome sandboxing (disabled by default) inside a container ([more details](https://docs.docker.com/engine/security/seccomp/))
- batch files examples when running on Windows:
  - [docker-help.bat](docker-help.bat): verify the proper running of the CLI by displaying the CLI help in a container.  Will work without a validated license key.
  - [docker-validateKey.bat](docker-validateKey.bat): validate a license key
  - [docker-genDoc.bat](docker-genDoc.bat): run the CLI for the genDoc command.  Requires a validated license key.



## Usage

### Build the image

#### Build the image with defaults

with a tag “hackolade:latest”:

`docker build --no-cache --pull -f Dockerfile.app -t hackolade:latest .`

The example uses a [Dockerfile.app](Dockerfile.app) which references the latest base [image](https://hub.docker.com/r/hackolade/studio) with all prerequisites needed to run Hackolade.  We chose to not include the Hackolade Studio application in the base image so it would remain stable, while the Dockefile.app instructions download the latest version.  

The image has a pre-created user “hackolade” with UID 1000 and GID 0, which may be needed to synchronize permissions between container and host system. This group GID is particularly important in the case 

Note that user / group inside a container should have access to mounted folders as well as host user to avoid permission issues: appData, data, logs, options.  This is why user UID/GIG mapping is necessary between the host and the container.

All necessary folder are setup at build time to be read/writable by any user part of the GID group defined at build time.



#### Build the image with a custom GID

If your container orchestrator runs containers with a specific group different from root group (0) inside containers then you need to adapt the build argument to your need.  For example, OpenShift defaults to users with arbitrary uids but with the 0 root group.

```bash
docker build --no-cache --pull -f Dockerfile.app -t hackolade:latest --build-arg=GID=12345 .
```



#### Build the image with a specific Hackolade Studio Desktop version / url

You may find previous versions of Hackolade Studio Desktop by replacing in the following URL v6.9.6 with v<version of your choice>, for example https://s3-eu-west-1.amazonaws.com/hackolade/previous/v6.9.6/Hackolade-linux-x64.zip


```bash
docker build --no-cache --pull -f Dockerfile.app -t hackolade:latest --build-arg=HACKOLADE_URL="<url to specific version zip path>" .
```
Note: make sure you are using an official Hackolade published version!  Don't trust other sources.



#### Plugins

If you need target plugins, they can be installed using one of the following methods:

- by editing the Dockerfile.app file before initial build, so the image immediately includes the selected plugin(s)

- afterwards, by making your selection in the [Dockerfile.plugins](Dockerfile.plugins) file, then running the following command:
  
  `docker build --no-cache -f Dockerfile.plugins -t hackolade:latest .`

If a plugin you need exists but is somehow not listed in your Dockerfile.plugins file, you can find the exhaustive list in the [plugin registry](https://github.com/hackolade/plugins/blob/master/pluginRegistry.json).  Then you may add a line (without the # comment): `RUN installPlugin.sh <plugin name> <plugin version>` You may activate multiple lines to install plugins at the same time. Plugin version is optional parameter, if it is omitted, the latest plugin will be downloaded.



To list existing plugins in your image:

`docker run --rm --entrypoint ls hackolade:latest /home/hackolade/.hackolade/plugins/`

To view the version number of a plugin in your image:

`docker run --rm --entrypoint cat hackolade:latest /home/hackolade/.hackolade/plugins/<plugin name>/package.json`



### Run CLI commands in a container

It is suggested to run commands using the [docker-compose.yml](Dockerfile.app) file, possibly after editing it for your specific needs.  The docker-compose file will ensure the presence of 4 required subfolders shared from the host, and if not, will create them,

         - ./appData:/home/hackolade/.config/Hackolade
         - ./data:/home/hackolade/Documents/data/
         - ./logs:/home/hackolade/Documents/HackoladeLogs/
         - ./options:/home/hackolade/.hackolade/options

where:

​			`- <host location>:<container location>`

The user inside the container must have enough permissions to write and read from these host folders.   If you don't use docker-compose, you must create them manually for proper operations.  You may also use absolute path with $PWD.

Description of required host subfolders:

- *data*: this folder is used to share files with containers.  It may contain models, documentation, sources for reverse-engineering, artefacts out of forward-engineering, etc...  Instead of a relative path to the location where the container is run, you may reference an absolute path to the location of these files.
- *options*; this folder is used to store custom properties for plugins, naming convention configuration, and Excel export options.  Instead of a relative path to the location where the container is run, you may reference an absolute path to the location of these files.
- *logs* and *appData*: these folders are necessary for the proper operation of the application in containers.

Note that you can also use named volumes but then you have to ensure to provide the expected license files expected by the application.



#### Display CLI help in a container

All commands must be executed in the parent folder of the subfolders described above.  It is suggested to run commands using the [docker-compose.yml](docker-compose.yml) file, possibly after editing it for your specific needs. 

A typical command will look like this:

```bash
docker compose run --rm hackoladeStudioCLI command [--arguments]
```


where:

- `hackoladeStudioCLI` is the name of the service as defined in docker-compose.yml
- `hackolade` invokes the application
- `command` is the CLI command
- `--arguments` is for optional arguments

Example:
```bash
docker compose run --rm hackoladeStudioCLI help
```

You may consult our [online documentation](https://hackolade.com/help/CommandLineInterface.html) for the full description of commands and their respective arguments.



#### Run the container with a different UID

The image has a bootstrap script that allows mapping the user running inside the container with specific UID or GID.  For example, imagine the user that owns the files inside the four volumes mounted inside the container is having UID=2023 and GID=0, we then need to configure our container as follows:

```bash
docker compose run --rm -u 2023 hackoladeStudioCLI command [--arguments]
```



#### Validate license key for the image

##### With Internet connection

All commands must be executed in the parent folder of the subfolders described above.  It is suggested to run commands using the [docker-compose.yml](Dockerfile.app) file, possibly after editing it for your specific needs.  The process is as follows:

1. Fetch the UUID of the image: `docker run --rm --entrypoint show-computer-id.sh hackolade:latest`   
2. Run the command:

```bash
docker compose run --rm hackoladeStudioCLI validatekey --key=<concurrent-license-key> --identifier=<UUID-fetched-in-step-1>
```

**Note:** The license key validation must be repeated for each new Docker image.



##### Without Internet connection

If your build server has no Internet connection, it is necessary to do an offline validation of your license key.  The process is as follows:

1. Fetch the UUID of the image: `docker run --rm --entrypoint show-computer-id.sh hackolade:latest`
2. From the browser of a computer with Internet access, go to this page: https://quicklicensemanager.com/hackolade/QlmCustomerSite/

 <img src="lib/Offline_license_activation.png" style="zoom:50%;" />

  - enter your license key in the "Activation Key" field
  - select the version "Hackolade 5.0" or above
  - enter the UUID fetched above in the "Computer ID" field
  - make sure to check the options "Generate a license file" and "I consent to the Privacy Policy"
  - click the Activate button

  A file LicenseFile.xml will be generated and downloaded by your browser. Do NOT edit or alter the content of the file as it contains integrity validation to prevent abuse.

3. copy the LicenseFile.xml to your build server in the *data* subfolder on the host:

   `./data`

   assuming the docker-compose.yml has been configured as:

   `./data:/home/hackolade/Documents/data/`

4. Validate the license key the command

   `docker compose run --rm hackoladeStudioCLI validatekey --key=<concurrent-license-key> --file=/home/hackolade/Documents/data/LicenseFile.xml`

**Important:** If your docker-compose.yml subfolder volumes configuration is different than the example above, please make sure to adjust the path accordingly, as the --file argument is a path inside the container.

**Note:** The entire above process must be repeated for each new Docker image as the UUID changes with each creation.



#### Example: generate documentation for a model

All commands must be executed in the parent folder of the subfolders described above.  It is suggested to run commands using the [docker-compose.yml](docker-compose.yml) file, possibly after editing it for your specific needs. 

Assuming that a valid Hackolade model file called *`model.json`* is placed in the *`data`* subfolder of the location where the container is being run:

`docker compose run --rm hackoladeStudioCLI genDoc --model=/home/hackolade/Documents/data/model.json --format=html --doc=/home/hackolade/Documents/data/doc.html`

This example can be adjusted to run any CLI command, as documented [here](https://hackolade.com/help/CommandLineInterface.html).



### Custom properties, naming conventions, Excel export options

You may have customized the behavior of the application GUI, and wish to use them during CLI processing.  

If the containers will be running on a machine with no Hackolade Studio GUI, you use in the [docker-compose.yml](docker-compose.yml) file the default subfolder of the location where the containers will be running:

         - ./options:/home/hackolade/.hackolade/options

Or you may reference an absolute path to the location of these files, if you're also running the Hackolade Studio GUI on the same Windows machine:

```Windows
     - C:/Users/%username%/.hackolade/options:/home/hackolade/.hackolade/options
```



### Running with root user downgrading to unprivileged hackolade user to adapt dynamically bind mounted volumes content

In some cases it is difficult to control the ownership of the four volumes used by Hackolade.  The image supports running as root during the initial container bootstrap to adapt files ownership automatically to the target user passed as `-e UID=<target uid>` and then run the Hackolade CLI using this unprivileged user as the main container process.  This mode is automatically turned on if the entrypoint detects the running user is root.

If you want to leverage that mode then you need to define `USER root` as the latest instruction of your Dockerfile.app or use the Docker run `-u root` parameter to set the running user as being root.




### Running with Electron Chrome sandboxing enabled

For simplicity and because of the security offered by containers and orchestrators we leverage the `--no-sandbox` Chrome flag.  This is also possible because we don't load any external site url/content but only local application code. 

Doing so allows us to remove the need for providing the **securityPolicies.json** file as a seccomp profile, as we used to do previously when running hackolade cli docker image.  Having to use this security profile may have been problematic in some security contexts.

If you prefer to still enableChrome sandboxing you can do like following and make sure you are using the **securityPolicies.json** file security profile.

```bash
docker compose run --rm -e WITH_SANDBOXING=true hackoladeStudioCLI command
```
