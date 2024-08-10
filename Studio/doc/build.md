# Build the image

## With latest available Hackolade directly from our Releases

```bash
docker build --no-cache --pull -t hackolade:latest .
```

The example uses a [Dockerfile](Dockerfile) which references the latest runtime [image](https://hub.docker.com/r/hackolade/studio) with all prerequisites needed to run Hackolade.

### With a specific Hackolade version directly from our Releases

```bash
docker build --no-cache --pull -t hackolade:latest --build-arg=HACKOLADE_URL="<url to specific version zip path>" .
```

Note: make sure you are using an official Hackolade published version!  Don't trust other sources.

## Installing Plugins

If you need target plugins, they can be installed during image build by editing the **Dockerfile** file before initial build, so the image comes immediately with the selected plugin(s) properly installed


If a plugin you need exists but is somehow not listed in your Dockerfile file, you can find the exhaustive list in the [plugin registry](https://github.com/hackolade/plugins/blob/master/pluginRegistry.json).  Then you may add a line (without the # comment): `RUN installPlugin.sh <plugin name> <plugin version>` You may activate multiple lines to install plugins at the same time. Plugin version is optional parameter, if it is omitted, the latest plugin will be downloaded.

### Validate plugins installation
To list existing plugins in your image:

```bash
docker run --rm --entrypoint ls hackolade:latest /home/hackolade/.hackolade/plugins/
```

To view the version number of a plugin in your image:

```bash
docker run --rm --entrypoint cat hackolade:latest /home/hackolade/.hackolade/plugins/<plugin name>/package.json
```

### Unprivileged user

The image has a pre-created unprivileged user **hackolade** with UID **1000** and GID **0**.  You may need to synchronize permissions between container and host system when mounting folders from the host.  The group **GID** is particularly important in the case the user is dynamically assigned in the container.

All necessary folders are setup at build time to be read/writable by any user part of the GID group defined at build time.

# (Offline alternative) Build the image if you have no Internet connection 

If your environment doesn't allow you to access our Hackolade releases directly, you will need to download the version you want to install and reference it into the Dockerfile to be able to install it.  Make sure you download a Linux version to be able to install it inside a Docker image.  You may find previous versions of Hackolade Studio Desktop by replacing in the following URL v6.9.6 with v<version of your choice>, for example [https://s3-eu-west-1.amazonaws.com/hackolade/previous/v6.9.6/Hackolade-linux-x64.zip](https://s3-eu-west-1.amazonaws.com/hackolade/previous/v6.9.6/Hackolade-linux-x64.zip).

1. First, download the Hackolade version you want to install ***nearby the Dockerfile*** and name the downloaded file ***Hackolade.zip***.  

2. Then, add the following lines to your Dockerfile

```dockerfile
    # Copy the local zip file you want to install 
    # (the file should be available in your build context so make sure to check potential .dockerignore file)
    COPY ./Hackolade.zip /tmp/Hackolade.zip

    # Install the Hackolade zip file from /tmp/Hackolade.zip
    RUN /usr/bin/install-hackolade.sh
```

- Then build the image with the Hackolade.zip file destination path in the Dockerfile as a build-argument:

```bash
docker build --no-cache -t hackolade:latest --build-arg=HACKOLADE_URL="/tmp/Hackolade.zip" .
```

Note that in such an offline case you need to also be able to access the source image (see first `FROM` instruction in our Dockerfile.app example).  This image can be accessed either from our Docker Hub, either from your internal Docker Registry if your administrators hosted a copy of our image.


## Install plugins without an Internet connection (offline)

If your environment doesn't allow you to install plugins directly from our repos, you will need to download each plugin from our GitHub organization plugin repositories and put them inside a plugins folder nearby the Dockerfile.

For example, if you need to install the plugin for MSSQL server, download the ***SQLServer-0.1.60.tar.gz*** source release from [the release page https://github.com/hackolade/SQLServer/releases](https://github.com/hackolade/SQLServer/releases) and put the archive into a plugins folder close to your Dockerfile.

Your file structure should be as follows:

```bash
Dockerfile
plugins/SQLServer-0.1.60.tar.gz
```

Then add the following line at the end of your Dockerfile (e.g. after the command `USER hackolade`) for each plugin you want to install:

```bash
ADD ./plugins/SQLServer-0.1.60.tar.gz /home/hackolade/.hackolade/plugins/
RUN mv /home/hackolade/.hackolade/plugins/SQLServer-0.1.60 /home/hackolade/.hackolade/plugins/SQLServer
```

Finally you can build the Docker image using 

```bash
docker build --no-cache -t hackolade:latest .
```
