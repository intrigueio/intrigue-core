#! /bin/bash

# Set path to include rbenv
source /root/.bash_profile

# prepare data dir for postgres
if [ ! -d /data/postgres ]; then
  sudo mkdir -p /data/postgres
fi

# set ownership
chown postgres:postgres /data/postgres

# initialize the postgres db 
echo "[+] Initializing database"
sudo -u postgres /usr/lib/postgresql/*/bin/initdb /data/postgres

echo "[+] Creating Intrigue DB"
sudo service postgresql restart
sudo -u postgres createuser intrigue
sudo -u postgres createdb intrigue_dev --owner intrigue

echo "[+] Migrating DB for Intrigue Standalone"
bundle exec rake db:migrate

echo "[+] Setting up Intrigue Standalone"
bundle exec rake setup

# prepare data dir for redis
if [ ! -d /data/redis ]; then
  sudo mkdir -p /data/redis
fi
chown redis:redis /data/redis

# restart redis 
echo "[+] Restarting redis"
sudo service redis restart

echo "[+] Enabling Intrigue Services"
god -c /core/util/god/intrigue-docker.rb
god start intrigue

echo "[+] Tailing worker log"
tail -f /core/log/worker.log
