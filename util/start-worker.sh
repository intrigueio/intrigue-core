#! /bin/bash

# Set path to include rbenv
source /root/.bash_profile


echo "[+] Setting up Intrigue Standalone"
bundle exec rake setup

echo "[+] Setting up Intrigue Database"
bundle exec rake db:migrate

echo "[+] Updating Intrigue Standalone"
bundle exec rake update

echo "[+] Starting Intrigue Worker"
god -c /core/util/god/intrigue-docker.rb
god start intrigue

echo "[+] Tailing worker log"
tail -f /core/log/worker.log
