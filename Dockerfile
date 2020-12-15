FROM ubuntu:20.04
MAINTAINER Intrigue Team <hello@intrigue.io>
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -y update && apt-get -y install sudo

# Set us up a user!
RUN useradd -ms /bin/bash ubuntu && echo "ubuntu:ubuntu" | chpasswd && adduser ubuntu sudo && echo "ubuntu ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
USER ubuntu
WORKDIR /home/ubuntu

# Set up intrigue
ENV BUNDLE_JOBS=12
ENV PATH /home/ubuntu/.rbenv/bin:$PATH
ENV IDIR=/home/ubuntu/core
ENV DEBIAN_FRONTEND=noninteractive

# create a volume
VOLUME /data

# copy intrigue code
COPY . core

# install intrigue-specific software & config
RUN /bin/bash core/util/bootstrap.sh

# Expose the port
EXPOSE 7777

RUN chmod +x core/util/intriguectl.sh
ENTRYPOINT ["./core/util/intriguectl.sh", "start"]
