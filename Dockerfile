FROM ubuntu:16.04
MAINTAINER Jonathan Cran <jcran@intrigue.io>

USER root

# get intrigue-core code
RUN apt-get -y update && apt-get -y install sudo
RUN /bin/bash -l -c "rm -rf /core && mkdir -p /core"
ADD . /core/

# Migrate!
WORKDIR /core

ENV BUNDLE_JOBS=12
ENV PATH /root/.rbenv/bin:$PATH
RUN chmod +x /core/util/bootstrap.sh
RUN /core/util/bootstrap.sh

# Expose a port
EXPOSE 7777

RUN service postgres restart
RUN /core/util/control.sh start

ENTRYPOINT ["/bin/bash"]
