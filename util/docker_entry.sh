#! /bin/bash
source ~/.bash_profile

echo "[+] Restarting Postgres..."
service postgresql restart

echo "[+] Restarting Redis..."
service redis-server restart

echo "[+] Restarting Intrigue..."
/core/util/control.sh start

echo "[+] Tailing sidekiq.log..."
tail -f /core/log/sidekiq*.log
