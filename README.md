# Hackolade repo for Docker files

This repository contains the **Dockerfile** and instructions for running [Hackolade](https://hackolade.com) applications published on [Docker Hub](https://hub.docker.com/).

This [Dockerfile](Studio/Dockerfile.app) for Hackolade Studio is an example of a full ready-to-use installation of Hackolade Studio.

The example uses an [image](https://hub.docker.com/layers/156675526/hackolade/studio/0.0.1/images/sha256-e07bd24cb67b0b6ccc59cee52fe563fd3a9f52f840e1776fcd446b3ec00c7cff?context=explore) with all prerequisites needed to run Hackolade. Also, it has a pre-created user “hackolade” with UID 1000 and GID 1000, which may be needed to synchronize permissions between container and host system.

**Important note**: each image building process generates a unique computer id.  Once you build an image and validate the license key, that license key will be coupled with this image until you release it.  So it is highly recommended **not** to push your image to a public place with a validated license key, or you risk begin unable to use your own key.

### Usage

#### Build the image

with a tag “hackolade:latest”:

`docker build -f Dockerfile.app -t hackolade:latest .`

#### Create 3 directories

*logs*, *data*, *appData*

The user inside the container should have enough permissions to write and read from these folders.  In unix environments, these should be created as subfolders in the **current** directory.  

For non-unix environments, you should manually create 

<to be continued>



https://hub.docker.com/r/hackolade/studio



