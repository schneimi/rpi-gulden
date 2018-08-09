# rpi-gulden
G-Dash: Gulden Witness & Node Dashboard for Docker

## Introduction
This is the attempt to port the G-Dash autoinstaller script from https://g-dash.nl/?page=download#autoinstall to Dockerfile and run G-DASH with Docker.

All processes will run in one container and be managed by Docker. That means if the process stops the container also stops. The auto restart of the container will be achieved by docker restart policy.

Use this Dockerfile at your own risk and please report any issues. Thx.

## Build arguments with default values
Override on build with `--build-arg` parameter.

    GULDEN_UID=1000                    - User id for Gulden process
    GULDEN_GID=1000                    - Group id for Gulden process
    GULDEN_PASSWORD=pipasswd           - Password for Gulden RPC
    GDASH_VERSION=1.02                 - G-Dash version in case a newer version is available
    GDASH_WEBLOCATION=http://localhost - The URL where G-Dash will be reachable

## There are two volumes defined to persist data
    /opt/gulden/datadir - Gulden configuration, wallet and block data
    /var/www            - G-Dash settings and web interface files that get updated on self upgrade

## Download the Dockerfile
https://raw.githubusercontent.com/schneimi/rpi-gulden/master/Dockerfile

## Build from Dockerfile location
This is the minimal build command for G-DASH v1.02. All other configuration can also be done via the G-DASH web interface.

    docker build --force-rm --tag schneimi/rpi-gulden \
        --build-arg GULDEN_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1) \
        .

Force a newer G-DASH version and already set some configuration.

    docker build --force-rm --tag schneimi/rpi-gulden \
        --build-arg GDASH_VERSION=1.02 \
        --build-arg GDASH_WEBLOCATION=http://localhost:8000 \
        --build-arg GULDEN_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1) \
        .

## Run the container
Choose the port e.g. `8000` where G-DASH should be accessible on your machine. This should match the port of your `GDASH_WEBLOCATION`.

    docker run --name gulden --restart always \
        -p 0.0.0.0:9231:9231 \
        -p 0.0.0.0:8000:80 \
        -d schneimi/rpi-gulden

Follow the instructions on G-DASH http://localhost:8000.

## Known issues
- Processes in the container should not run as root.
- The synchronisation with the blockchain requires much resources. If you experience memory problems like segmentation faults, try [zram](https://en.wikipedia.org/wiki/Zram) to compress your RAM.
- Notification with PushBullet will not be send on server down as this functionality also dies with the container.
