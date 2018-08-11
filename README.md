# rpi-gulden

G-DASH: Gulden Witness & Node Dashboard for Docker on Raspberry Pi 3B+ (e.g. using [Hypriot](https://blog.hypriot.com/)).

## Introduction

This is the attempt to port the G-DASH autoinstaller script from <https://g-dash.nl/?page=download#autoinstall> to a Dockerfile and run G-DASH with Docker.

All process will run in one container that is managed by Docker. That means if the process stops the container also stops. The auto restart of the container is achieved by docker restart policy.

This is not a final version, just a version that works for me. Also I am no Docker expert, so please use this Dockerfile at your own risk and please report any issues and help to improve it.

## Dockerfile

The image is based on the latest [Raspbian Stretch](https://www.raspberrypi.org/downloads/raspbian/) and will install the G-DASH web interface on top of an Apache web server and a Gulden node.

### Volumes

The following volumes are defined to persist data.

```
/opt/gulden/datadir - Gulden configuration, wallet and block data
/var/www            - G-Dash settings and web interface files that get replaced on self upgrade

```

## Installation

Download the Dockerfile:

<https://raw.githubusercontent.com/schneimi/rpi-gulden/master/Dockerfile>

### Build the image

Build the image from the Dockerfile location. Override the following default values on `docker build` using the `--build-arg` parameter.

```
GULDEN_UID=1000                    - User id for Gulden process
GULDEN_GID=1000                    - Group id for Gulden process
GULDEN_PASSWORD=pipasswd           - Password for Gulden RPC
GDASH_VERSION=1.02                 - G-Dash version in case a newer version is available
GDASH_WEBLOCATION=http://localhost - The URL where G-Dash will be reachable
APACHE_SERVER_NAME=localhost       - The Apache web server name

```

This is the minimal build command for G-DASH v1.02 that sets a generated password.

```
docker build --force-rm --tag schneimi/rpi-gulden \
    --build-arg GULDEN_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1) \
    .

```

This is an example how to force a newer G-DASH version (may not exist yet at the time of reading) and already set the web location with your preferred port e.g. `8000`.

```
docker build --force-rm --tag schneimi/rpi-gulden \
    --build-arg GDASH_VERSION=1.03 \
    --build-arg GDASH_WEBLOCATION=http://localhost:8000 \
    --build-arg APACHE_SERVER_NAME=localhost:8000 \
    --build-arg GULDEN_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1) \
    .

```

## Run the container

The port where G-DASH should be reachable on your machine must be mapped to the internal port `80` of the apache web server. Replace `80:80` with e.g. `8000:80` if you want to use port 8000. This port should also match the port of your `GDASH_WEBLOCATION`.

```
docker run --name gulden --restart always \
    -p 0.0.0.0:9231:9231 \
    -p 0.0.0.0:80:80 \
    -d schneimi/rpi-gulden

```

Open <http://localhost> and follow the instructions of G-DASH! :smiley:

## Known issues

* Processes in the container should not run as root.
* The synchronisation with the blockchain requires much resources. If you experience memory problems like segmentation faults, try [zram](https://en.wikipedia.org/wiki/Zram) to compress your RAM.
* Notification with PushBullet will not be send on server down as this functionality also dies with the container. I am not sure if notifications actually work at all, as I didn't receive any notification yet.
