#! /bin/bash

# Set path to include rbenv
source /root/.bash_profile

echo "[+] Migrating DB for Intrigue Standalone"
bundle exec rake db:migrate

echo "[+] Setting up Intrigue Standalone"
bundle exec rake setup

echo "[+] Enabling Intrigue Services"
god -c /core/util/god/intrigue-docker.rb
god start intrigue

echo "[+] Tailing worker log"
tail -f /core/log/worker.log
