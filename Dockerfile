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

# copy intrigue code
COPY --chown=ubuntu:ubuntu . core

# install intrigue-specific software & config
RUN /bin/bash ./core/util/bootstrap.sh

# Expose the port
EXPOSE 7777

# create entrypoint file
WORKDIR /home/ubuntu
CMD touch docker-entrypoint.sh
RUN printf "#!/bin/bash \
\n #source ~/.bash_profile \
\n # \
\n # move postgres to /data \
\n if [ -d \"/data\" ]; then \
\n  echo \"[+] Found /data directory!\" \
\n  sudo service postgresql stop > /dev/null \
\n  if [ ! -d \"/data/postgres\" ]; then \
\n      echo \"[+] Creating and moving postgres to /data/postgres\" \
\n      sudo mkdir -p /data/postgres \
\n      sudo chown postgres:postgres /data/postgres \
\n      sudo chmod 700 /data/postgres \
\n      sudo -u postgres /usr/lib/postgresql/*/bin/initdb /data/postgres > /dev/null 2> /dev/null \
\n  else \
\n      echo \"[+] Moving postgres to /data/postgres\" \
\n      sudo chown -R postgres:postgres /data/postgres \
\n      sudo chmod 700 /data/postgres \
\n  fi \
\n  sudo sed -i \"s/data_directory = .*/data_directory = '\/data\/postgres'/g\" /etc/postgresql/*/main/postgresql.conf \
\n  sudo service postgresql start > /dev/null \
\n  sudo -u postgres createuser intrigue 2>/dev/null \
\n  sudo -u postgres createdb intrigue_dev --owner intrigue 2>/dev/null \
\n  # \
\n  # move redis to /data \
\n  sudo service redis-server stop > /dev/null \
\n  if [ ! -d \"/data/redis\" ]; then \
\n      echo \"[+] Creating and moving redis to /data/redis\" \
\n      sudo mkdir /data/redis \
\n      sudo chown redis:redis /data/redis \
\n      sudo chmod -R 770 /data/redis \
\n  else \
\n      echo \"[+] Moving redis to /data/redis\" \
\n      sudo chown -R redis:redis /data/redis \
\n      sudo chmod 770 /data/redis \
\n  fi \
\n  sudo sed -i '/^bind/s/bind.*/bind 127.0.0.1/' /etc/redis/redis.conf \
\n  sudo sed -i 's/dir \/var\/lib\/redis/dir \/data\/redis/g' /etc/redis/redis.conf \
\n  sudo mkdir /etc/systemd/system/redis-server.service.d \
\n  sudo touch /etc/systemd/system/redis-server.service.d/override.conf \
\n  sudo sh -c 'echo \"[Service]\" >> /etc/systemd/system/redis-server.service.d/override.conf' \
\n  sudo sh -c 'echo \"ReadWriteDirectories=-/data/redis\" >> /etc/systemd/system/redis-server.service.d/override.conf' \
\n  sudo sh -c 'echo \"ProtectHome=no\" >> /etc/systemd/system/redis-server.service.d/override.conf' \
\n  sudo service redis-server start > /dev/null \
\n  # \
\n else \
\n  sudo service postgresql start > /dev/null \
\n  sudo service redis-server start > /dev/null \
\n fi \
\n # \
\n # Remove instructions because we're in Docker\
\n sed -i \"s/boxes -a c .*//\" ~/.bash_profile \
\n sed -i \"s/Browse to https:\/\/.ip:7777/Browse to https:\/\/localhost:7777/\" /home/ubuntu/core/util/intriguectl \
\n sed -i \"s/To start intrigue, run 'intriguectl start'//\" /home/ubuntu/core/util/intriguectl \
\n source ~/.bash_profile \
\n # setup and start commands \
\n /home/ubuntu/core/util/intriguectl setup \
\n /home/ubuntu/core/util/intriguectl start \
\n tail -f /home/ubuntu/core/log/worker.log" >> docker-entrypoint.sh

RUN chmod +x docker-entrypoint.sh

# run it
ENTRYPOINT ["/home/ubuntu/docker-entrypoint.sh"]
