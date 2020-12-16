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
COPY --chown=ubuntu:ubuntu . core

USER ubuntu
# install intrigue-specific software & config
RUN /bin/bash ./core/util/bootstrap.sh

# Expose the port
EXPOSE 7777

# create entrypoint file
WORKDIR /home/ubuntu
CMD touch docker-starter.sh
RUN printf "#!/bin/bash \
\n source ~/.bash_profile \
\n # \
\n # move postgres to /data \
\n sudo service postgresql stop \
\n sudo mkdir -p /data/postgres \
\n sudo chown postgres:postgres /data/postgres \
\n sudo chmod 644 /data/postgres \
\n sudo -u postgres /usr/lib/postgresql/*/bin/initdb /data/postgres \
\n sudo sed -i \"s/data_directory = .*/data_directory = '\/data\/postgres'/g\" /etc/postgresql/*/main/postgresql.conf \
\n sudo service postgresql start \
\n sudo -u postgres createuser intrigue 2>/dev/null \
\n sudo -u postgres createdb intrigue_dev --owner intrigue 2>/dev/null \
\n # \
\n # move redis to /data \
\n sudo service redis-server stop \
\n sudo mkdir /data/redis \
\n sudo chown redis:redis /data/redis \
\n sudo chmod -R 770 /data/redis \
\n sudo sed -i '/^bind/s/bind.*/bind 127.0.0.1/' /etc/redis/redis.conf \
\n sudo sed -i 's/dir \/var\/lib\/redis/dir \/data\/redis/g' /etc/redis/redis.conf \
\n sudo mkdir /etc/systemd/system/redis-server.service.d \
\n sudo touch /etc/systemd/system/redis-server.service.d/override.conf \
\n sudo sh -c 'echo \"[Service]\" >> /etc/systemd/system/redis-server.service.d/override.conf' \
\n sudo sh -c 'echo \"ReadWriteDirectories=-/data/redis\" >> /etc/systemd/system/redis-server.service.d/override.conf' \
\n sudo sh -c 'echo \"ProtectHome=no\" >> /etc/systemd/system/redis-server.service.d/override.conf' \
\n sudo service redis-server start \
\n # \
\n # remove old data directories \
\n sudo rm -rf /var/lib/pgsql/* \
\n sudo rm -rf /var/lib/pgsql/backups/* \
\n sudo rm -rf /var/lib/pgsql/data/ \
\n # \
\n # setup and start commands \
\n /home/ubuntu/core/util/intriguectl.sh setup \
\n /home/ubuntu/core/util/intriguectl.sh start \
\n tail -f /home/ubuntu/core/log/worker.log" >> docker-starter.sh

RUN chmod +x docker-starter.sh

# run it
ENTRYPOINT ["/home/ubuntu/docker-starter.sh"]
