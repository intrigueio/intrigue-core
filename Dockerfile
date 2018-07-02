FROM ubuntu:16.04
MAINTAINER Jonathan Cran <jcran@intrigue.io>
ENV DEBIAN_FRONTEND noninteractive

USER root

# Expose the port
EXPOSE 7777

# Get intrigue-core code
RUN apt-get -y update && apt-get -y install sudo
RUN /bin/bash -l -c "rm -rf /core && mkdir -p /core"
ADD . /core/

# Migrate!
WORKDIR /core

ENV BUNDLE_JOBS=12
ENV PATH /root/.rbenv/bin:$PATH
RUN chmod +x /core/util/bootstrap.sh
RUN /core/util/bootstrap.sh
RUN chmod +x /core/util/docker_entry.sh

ENTRYPOINT ["/core/util/docker_entry.sh"]
