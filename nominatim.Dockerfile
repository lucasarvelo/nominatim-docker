FROM ubuntu:jammy AS build

# Set environment variables
ENV USERNAME nominatim
ENV USERHOME /srv/nominatim
ENV DEBIAN_FRONTEND noninteractive
ENV LANG C.UTF-8
ENV NOMINATIM_VERSION=4.2.3
ENV PROJECT_DIR ~/nominatim-planet
ENV TREADS 4
ENV OSMFILE = OSMFILE_ARG
ENV IMPORTFILE = IMPORTFILE_ARG

# Set arguments
ARG USER_AGENT=mediagis/nominatim-docker:${NOMINATIM_VERSION}
ARG OSMFILE_ARG=${PROJECT_DIR}/data.osm.pbf
ARG IMPORTFILE_ARG


# Install dependencies
RUN apt update -qq
RUN true \
    # Do not start daemons after installation.
    && echo '#!/bin/sh\nexit 101' > /usr/sbin/policy-rc.d \
    && chmod +x /usr/sbin/policy-rc.d \
    # Install all required packages.
    && apt -y update -qq \
    && apt -y install \
        locales \
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8 \
    && apt -y install \
        -o APT::Install-Recommends="false" \
        -o APT::Install-Suggests="false" \
        # Build tools from sources.
        build-essential \
        g++ \
        cmake \
        libpq-dev \
        zlib1g-dev \
        libbz2-dev \
        libproj-dev \
        libexpat1-dev \
        libboost-dev \
        libboost-system-dev \
        libboost-filesystem-dev \
        liblua5.4-dev \
        # PHP and Apache 2.
        php \
        php-intl \
        php-pgsql \
        php-cgi \
        apache2 \
        libapache2-mod-php \
        # Python 3.
        python3-dev \
        python3-pip \
        python3-tidylib \
        python3-psycopg2 \
        python3-setuptools \
        python3-dotenv \
        python3-psutil \
        python3-jinja2 \
        python3-datrie \
        python3-icu \
        python3-argparse-manpage \
        # Misc.
        git \
        curl \
        sudo \
        sshpass \
        openssh-client

# Osmium install to run continuous updates.
RUN pip3 install osmium

# Create nominatim user
RUN sudo useradd -d ${USERHOME} -s /bin/bash -m ${USERNAME}

# Change access permisions to nominatim user home 
RUN chmod a+x ${USERHOME}

# Nominatim install.
WORKDIR ${USERHOME}

RUN true \
    && curl -A $USER_AGENT https://nominatim.org/release/Nominatim-$NOMINATIM_VERSION.tar.bz2 -o nominatim.tar.bz2 \
    && tar xf nominatim.tar.bz2 \
    && mkdir build \
    && cd build \
    && cmake ../Nominatim-$NOMINATIM_VERSION \
    && make -j`nproc` \
    && make install

# Import nominatim database
WORKDIR ${PROJECT_DIR}

COPY ${IMPORTFILE} ${OSMFILE}

RUN sudo -E -u nominatim nominatim import --osm-file ${OSMFILE} --threads $THREADS

# Apache configuration
COPY apache.conf /etc/apache2/sites-enabled/000-default.conf

COPY apache-start.sh /apache-start.sh

ENTRYPOINT [ "/apache-start.sh" ]