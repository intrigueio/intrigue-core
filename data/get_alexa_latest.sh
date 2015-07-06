#!/bin/bash

wget -N -q http://s3.amazonaws.com/alexa-static/top-1m.csv.zip
unzip top-1m.csv.zip
mv top-1m.csv alexa-latest.csv
rm top-1m.csv.zip
