#! /bin/bash

# Set path to include rbenv
source $HOME/.bash_profile

# Set up database if it's not already there 
if [ ! -d /data/postgres ]; then
  echo "[+] Configuing postgres"
  sudo mkdir -p /data/postgres
  sudo chown postgres:postgres /data/postgres
  sudo -u postgres /usr/lib/postgresql/*/bin/initdb /data/postgres > /dev/null
fi 

# now start the service 
echo "[+] Starting postgres"
sudo service postgresql start

# force user/db creation, just in case
sudo -u postgres createuser intrigue
sudo -u postgres createdb intrigue_dev --owner intrigue

if [ ! -d /data/redis ]; then
  sudo mkdir -p /data/redis
  sudo chown redis:redis /data/redis
fi 

# now we can starts services
echo "[+] Starting redis"
sudo service redis-server start

echo "[+] Migrating DB for Intrigue Standalone"
bundle exec rake db:migrate

echo "[+] Setting up Intrigue Standalone"
bundle exec rake setup

echo "[+] Enabling Intrigue Services"
god -c /core/util/god/intrigue-docker.rb
god start intrigue

echo "[+] Tailing worker log"
tail -f /core/log/worker.log
