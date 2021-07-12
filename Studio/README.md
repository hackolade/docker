# Running Hackolade Studio CLI in Docker 

The purpose of running Hackolade Studio in a Docker container is for running the Command-Line Interface ("CLI"), typically in a the context of integration with CI/CD pipelines.  It is **not** to run the application GUI, a use case which has not been tested.

**Important note:**  the CLI requires a **concurrent** license key with an available seat.  An individual workstation license of Hackolade is **not** sufficient.  To ensure that your CI/CD pipeline jobs always have an available seat, you may want to get a concurrent license key dedicated to this purpose.  On a single machine, multiple containers of the same image can be run in parallel with a concurrent license key.  
To purchase a concurrent license, perpetual or subscription, please send an email to support@hackolade.com. 



This repository contains files and instructions for running [Hackolade](https://hackolade.com) applications published on [Docker Hub](https://hub.docker.com/r/hackolade/studio):

- [Dockerfile.app](Studio/Dockerfile.app): ready-to-use example of a full installation of Hackolade Studio, including the possibility to install selected target plugins
- [Dockerfile.plugins](Studio/Dockerfile.app): example of a how to install additional target plugins
- [docker-compose.yml](Studio/Dockerfile.app): example of how to configure the launch of containers of the Hackolade CLI
- [docker-help.bat](Studio/Dockerfile.app): example of how to verify the proper running of the CLI by displaying the CLI help in a container (Windows).  This example will work without a validated license key.
- [docker-validateKey.bat](Studio/Dockerfile.app): example of how to validate a license key (Windows)
- [docker-genDoc.bat](): example of how to run the CLI for the genDoc command (Windows).  This command requires a validated license key.



## Usage

### Build the image

with a tag “hackolade:latest”:

`docker build --no-cache -f Dockerfile.app -t hackolade:latest .`

The example uses a [Dockerfile.app](https://hub.docker.com/repository/docker/hackolade/studio) which references a base [image](https://hub.docker.com/repository/docker/hackolade/studio) with all prerequisites needed to run Hackolade.  The latest version of Hackolade will automatically be downloaded.  The image has a pre-created user “hackolade” with UID 1000 and GID 1000, which may be needed to synchronize permissions between container and host system.  



#### Plugins

If you need target plugins, they can be installed using one of the following methods:

- by editing the Dockerfile.app file before initial build, so the image immediately includes the selected plugin(s)
- afterwards, by making your selection in the [Dockerfile.plugins](https://hub.docker.com/repository/docker/hackolade/studio) file, then running the following command:
  `docker build --no-cache -f Dockerfile.plugins -t hackolade:latest .`

To list existing plugins in your image:

`docker run --rm hackolade:latest ls .hackolade/plugins/`

To view the version number of a plugin in your image:

`docker run --rm hackolade:latest cat .hackolade/plugins/<plugin name>/package.json`



### Run commands in a container

It is suggested to run commands using the [docker-compose.yml](Studio/Dockerfile.app) file, possibly after editing it for your specific needs.  The docker-compose file will ensure the presence of 4 required subfolders, and if not, will create them:

         - ./appData:/home/hackolade/.config/Hackolade
         - ./data:/home/hackolade/Documents/data/
         - ./logs:/home/hackolade/Documents/HackoladeLogs/
         - ./options:/home/hackolade/.hackolade/options

If you don't use docker-compose, you must create them manually for proper operations.

Description of required subfolders:

- *data*: this folder is used to share files with containers.  It may contain models, documentation, sources for reverse-engineering, artefacts out of forward-engineering, etc...  Instead of a relative path to the location where the container is run, you may reference an absolute path to the location of these files.
- *options*; this folder is used to store custom properties for plugins, naming convention configuration, and Excel export options.  Instead of a relative path to the location where the container is run, you may reference an absolute path to the location of these files.
- *logs* and *appData*: these folders are necessary for the proper operation of the application in containers.





### Update to the latest application and plugin versions









#### Custom properties, naming conventions, Excel export options





#### Create 3 directories

*logs*, *data*, *appData*

The user inside the container should have enough permissions to write and read from these folders.  In unix environments, these should be created as subfolders in the **current** directory.  

For non-unix environments, you should manually create 

<to be continued>



https://hub.docker.com/r/hackolade/studio



