FROM ubuntu:20.04
MAINTAINER Intrigue Team <hello@intrigue.io>
ENV DEBIAN_FRONTEND noninteractive

USER root

# Get up to date
RUN apt-get -y update && apt-get -y install sudo

# Set us up!
WORKDIR /core

# Set up intrigue
ENV BUNDLE_JOBS=12
ENV PATH /root/.rbenv/bin:$PATH
ENV IDIR=/core
ENV DEBIAN_FRONTEND=noninteractive

# create a volume
VOLUME /data

# copy intrigue code
COPY . /core/

# install intrigue-specific software & config
RUN /bin/bash /core/util/bootstrap-standalone.sh

# Remove the config file so one generates on startup (useful when testing)
RUN if [ -e /core/config/config.json ]; then rm /core/config/config.json; fi

# Expose the port
EXPOSE 7777

RUN chmod +x /core/util/start-standalone.sh
ENTRYPOINT ["/core/util/start-standalone.sh"]
