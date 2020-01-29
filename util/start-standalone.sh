#! /bin/bash

# Set path to include rbenv
source /root/.bash_profile


# prepare data dir for postgres
if [ ! -d /data/postgres ]; then
  sudo mkdir -p /data/postgres
  
  # always reset permission
  chown postgres:postgres /data/postgres

  # initialize the postgres db 
  echo "[+] Initializing database"
  sudo -u postgres /usr/lib/postgresql/*/bin/initdb /data/postgres

  # creating database 
  echo "[+] Creating Intrigue DB"
  sudo service postgresql start
  sudo -u postgres createuser intrigue
  sudo -u postgres createdb intrigue_dev --owner intrigue
else
  # always reset permission
  chown postgres:postgres /data/postgres
fi 
sudo service postgres restart

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
sudo service postgresql restart redis

echo "[+] Enabling Intrigue Services"
god -c /core/util/god/intrigue-docker.rb
god start intrigue

echo "[+] Tailing worker log"
tail -f /core/log/worker.log
