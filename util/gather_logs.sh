#! /bin/bash
CURRENT_DATE=`date +%Y%m%d`
FILENAME="intrigue-logs-$CURRENT_DATE"

# Zip it up and drop it in the current directory
tar -zcvf log/* $FILENAME
echo "[+] Stored in $FILENAME"

cp $FILENAME.zip ./public
