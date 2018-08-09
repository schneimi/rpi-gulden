FROM raspbian/stretch
MAINTAINER Michael Schneidt <michael.schneidt@arcor.de>

# declare non interactive mode to avoid error messages
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# adding gulden repository to the raspbian sources
RUN sh -c 'echo "deb http://raspbian.gulden.com/repo/ stretch main" > /etc/apt/sources.list.d/gulden.list'

# updating the system
RUN apt-get update && apt-get -y upgrade

# install packages
RUN apt-get install -y \
    curl \
    apache2 \
    php \
    libapache2-mod-php \
    php-curl \
    php-json \
    php-cli

# build arguments with default values
ARG GULDEN_UID=1000
ARG GULDEN_GID=1000
ARG GULDEN_PASSWORD=pi
ARG GDASH_VERSION=1.02
ARG GDASH_WEBLOCATION=http://localhost

# environment variables
ENV GULDEN_USER=pi \
    GULDEN_PASSWORD=$GULDEN_PASSWORD \
    GULDEN_HOME=/home/pi \
    GULDEN_DIR=/opt/gulden \
    GULDEN_DAEMON_DIR=/opt/gulden/gulden \
    GULDEN_DATADIR=/opt/gulden/datadir \
    GULDEN_CONF=/opt/gulden/datadir/Gulden.conf \
    GDASH_DIR=/var/www/html \
    GDASH_VERSION=$GDASH_VERSION \
    GDASH_DOWNLOAD=https://g-dash.nl/download/G-DASH-${GDASH_VERSION}.tar.gz \
    GDASH_TAR=G-DASH-${GDASH_VERSION}.tar.gz \
    GDASH_VERSION=$GDASH_VERSION \
    GDASH_WEBLOCATION=$GDASH_WEBLOCATION

# create user required by gulden
RUN groupadd -g $GULDEN_GID $GULDEN_USER &&\
    useradd --no-log-init -r -u $GULDEN_UID -g $GULDEN_GID $GULDEN_USER &&\
    mkdir -p $GULDEN_HOME &&\
    chown -R $GULDEN_USER:$GULDEN_USER $GULDEN_HOME

# configure web server
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf &&\
    rm /var/www/html/index.html

# install gulden
RUN apt-get -y --allow-unauthenticated install gulden

# create gulden config file
RUN printf "maxconnections=60\nrpcuser=${GULDEN_USER}\nrpcpassword=${GULDEN_PASSWORD}" > $GULDEN_DATADIR/Gulden.conf

# install g-dash web interface
RUN mkdir $GULDEN_HOME/tmp && cd $GULDEN_HOME/tmp &&\
    wget $GDASH_DOWNLOAD &&\
    tar -xf $GDASH_TAR --directory $GDASH_DIR &&\
    cp $GDASH_DIR/config/config_sample.php $GDASH_DIR/config/config.php &&\
    chown -R www-data:www-data $GDASH_DIR

# create g-dash config file
RUN mv $GDASH_DIR/config/config_sample.php $GDASH_DIR/config/config.php && chown $GULDEN_USER:$GULDEN_USER $GDASH_DIR/config/config.php &&\
    printf "<?php \$CONFIG = array(\n'weblocation' => '${GDASH_WEBLOCATION}',\n'guldenlocation' => '${GULDEN_DAEMON_DIR}/',\n'datadir' => '${GULDEN_DATADIR}/',\n'rpcuser' => '${GULDEN_USER}',\n'rpcpass' => '${GULDEN_PASSWORD}',\n'dashversion' => '${GDASH_VERSION}',\n'configured' => '0',\n'rpchost' => '127.0.0.1',\n'rpcport' => '9232',\n); ?>" > $GDASH_DIR/config/config.php 

# create gulden startup script
RUN printf "#!/bin/bash\necho \"Stopping GuldenD service\"\n${GULDEN_DAEMON_DIR}/Gulden-cli -datadir=${GULDEN_DATADIR} stop\nsleep 5\n\necho \"Killing GuldenD\"\nkillall -9 GuldenD\nsleep 5\n\necho \"Checking for Gulden update\"\napt-get update\napt-get -y --allow-unauthenticated install gulden\nsleep 5\n\necho \"Removing peers.dat\"\nrm ${GULDEN_DATADIR}/peers.dat\nsleep 5\n\necho \"Starting GuldenD\"\n${GULDEN_DAEMON_DIR}/GuldenD -datadir=${GULDEN_DATADIR}" > $GULDEN_DIR/guldenstart.sh &&\
    chmod a+rwx $GULDEN_DIR/guldenstart.sh

# make gulden bin files executable
RUN chmod -R a+rwx $GULDEN_DAEMON_DIR

# create log files and set permission
RUN touch $GULDEN_DATADIR/debug.log && chmod 0644 $GULDEN_DATADIR/debug.log

# cleanup
RUN rm -Rf $GULDEN_HOME/tmp &&\
    rm -rf /var/lib/apt/lists/*

# create volumes for persisting gulden and g-dash data
VOLUME ["/opt/gulden/datadir", "/var/www"]

# start web server and gulden
CMD service apache2 start && $GULDEN_DIR/guldenstart.sh

# expose ports for apache and gulden node
EXPOSE 80 9231
