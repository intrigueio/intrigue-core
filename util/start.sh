#! /bin/bash

# Set path to include rbenv
source $HOME/.bash_profile

# check if we are a worker or a standalone 
if [[ -z "${WORKER_CONFIG}" ]]; then
  echo "We are a worker-only configuration!"
  SETUP_DATABASE="false"
else
  echo "We are a standalone configuration!"
  SETUP_DATABASE="true"
fi

###
### If we're a standlone configuration, go ahead and
### manage the database configuration / spin up 
###
if [ -z "${SETUP_DATABASE}" ]

  ###
  ### Adjust and spin up postgres
  ###

  # now we can starts services
  echo "[+] Stopping postgres"
  sudo service postgres stop

  # Set up database if it's not already there 
  if [ ! -d /data/postgres ]; then
    echo "[+] Configuing postgres"
    sudo mkdir -p /data/postgres
    sudo chown postgres:postgres /data/postgres 2>&1 /dev/null
    sudo -u postgres /usr/lib/postgresql/*/bin/initdb /data/postgres 2>&1 /dev/null
  fi 

  # now start the service 
  echo "[+] Starting postgres"
  sudo service postgresql start

  # force user/db creation, just in case
  sudo -u postgres createuser intrigue 2>&1 /dev/null
  sudo -u postgres createdb intrigue_dev --owner intrigue 2>&1 /dev/null

  ###
  ### Adjust and spin up redis
  ###

  if [ ! -d /data/redis ]; then
    sudo mkdir -p /data/redis
    sudo chown redis:redis /data/redis
  fi 

  # now we can starts services
  echo "[+] Starting redis"
  sudo service redis-server start
fi 

echo "[+] Migrating DB for Intrigue Standalone"
bundle exec rake db:migrate

echo "[+] Setting up Intrigue Standalone"
bundle exec rake setup

if [ -f /.dockerenv ]; then
  echo "[+] Starting Intrigue Services"
  god -c /core/util/god/intrigue.rb
  god start intrigue

  echo "[+] Tailing worker log"
  tail -f /core/log/worker.log
fi 