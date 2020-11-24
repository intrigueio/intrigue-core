#! /bin/bash
CURRENT_DATE=`date +%Y%m%d`
FILENAME="intrigue-logs-$CURRENT_DATE"
IDIR=/core 

cd $IDIR
echo "[+] Stopping services"
god stop intrigue

# Zip it up and drop it in the current directory
tar -zcvf $FILENAME.tar.gz log/
echo "[+] Stored in $FILENAME.tar.gz"

cp $FILENAME.tar.gz ./public/

echo "[+] Restarting services"
god start intrigue

echo "[+] Access this file at:"
echo "[+] https://`hostname`:7777/$FILENAME.tar.gz"
