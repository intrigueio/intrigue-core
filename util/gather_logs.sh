#! /bin/bash
CURRENT_DATE=`date +%Y%m%d`
FILENAME="intrigue-logs-$CURRENT_DATE"

echo "[+] Stopping services"
rbenv sudo service intrigue stop

# Zip it up and drop it in the current directory
tar -zcvf $FILENAME.tar.gz log/
echo "[+] Stored in $FILENAME.tar.gz"

cp $FILENAME.tar.gz ./public/

echo "[+] Restarting services"
rbenv sudo service intrigue start

echo "[+] Access this file at"
echo "[+] http://[servername]:7777/$FILENAME.tar.gz"
