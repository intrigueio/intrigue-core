FROM ubuntu:20.04
MAINTAINER Intrigue Team <hello@intrigue.io>
ENV DEBIAN_FRONTEND noninteractive

USER root

# Get up to date
RUN apt-get -y update && apt-get -y install sudo

# Set us up!
WORKDIR /home/ubuntu/core

# Set up intrigue
ENV BUNDLE_JOBS=12
ENV PATH /home/ubuntu/.rbenv/bin:$PATH
ENV IDIR=/home/ubuntu/core
ENV DEBIAN_FRONTEND=noninteractive

# create a volume
VOLUME /data

USER ubuntu

# copy intrigue code
COPY . /home/ubuntu/core/

# install intrigue-specific software & config
RUN /bin/bash /home/ubuntu/core/util/bootstrap.sh

# Expose the port
EXPOSE 7777

RUN chmod +x /home/ubuntu/core/util/start.sh
ENTRYPOINT ["/home/ubuntu/core/util/start.sh"]
