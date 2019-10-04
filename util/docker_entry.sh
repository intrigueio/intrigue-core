#! /bin/bash
#source ~/.bash_profile

echo "[+] Restarting Postgres..."
service postgresql restart

echo "[+] Restarting Redis..."
service redis-server restart

echo "[+] Restarting Intrigue..."
foreman start -e /core/util/env-prod-docker

echo "[+] Tailing sidekiq.log..."
tail -f /core/log/sidekiq*.log
