#! /bin/bash

# just in case?
source ~/.bash_profile

echo "[+] Starting Postgresql Service"
sudo service postgresql restart

echo "[+] Starting Redis Service"
sudo service redis-server restart

echo "[+] Setting up Intrigue Engine"
bundle exec rake db:setup

echo "[+] Enabling Intrigue Services"
god -c /core/util/god/intrigue-docker.rb -D
