#!/bin/bash

USER=[username]
PASS=[password]
HOST=[hostname]
FILE=[filename]

while true; do
  echo "[x] Splitting file"
  ruby ./es_split.rb $FILE
  echo "[x] Sending files to Elasticsearch"
  for x in `ls $FILE.*`; do
    echo "[x] File: $x"
    curl -s -XPOST https://$USER:$PASS@$HOST/_bulk --data-binary @../results/$x;
  done
  rm *.$FILE.*
  sleep 90;
done
