#!/bin/bash

# GeoLiteCity download function
function get_maxmind() {
  echo "[+] Getting latest MaxMind GeoLite2-City database"
  # get and unzip
  wget -N -q  https://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz 
  tar -zxf GeoLite2-City*.tar.gz
  # remove the file
  rm GeoLite2-City.tar.gz
  # move the file into the right place
  mv GeoLite2-City_*/GeoLite2-City.mmdb .
  # clean up
  rm -rf GeoLite2-City_*
}

# GeoLiteCity
if [ -d "geolitecity" ]; then
  cd geolitecity
  if [ ! -f GeoLite2-City.mmdb ]; then
    get_maxmind
  else
    get_maxmind
  fi
  cd ..
fi

# Web Account List
#  https://raw.githubusercontent.com/WebBreacher/WhatsMyName
if [ -d "web_accounts_list" ]; then
  cd web_accounts_list
  echo "[+] Getting latest web_accounts_list.json"
  wget -N -q https://raw.githubusercontent.com/WebBreacher/WhatsMyName/master/web_accounts_list.json
  cd ..
fi

# IANA address space
#  https://www.iana.org/assignments/ipv4-address-space/ipv4-address-space.xhtml
if [ -d "iana" ]; then
  cd iana
  echo "[+] Getting latest ipv4-address-space.csv"
  wget -N -q https://www.iana.org/assignments/ipv4-address-space/ipv4-address-space.csv

  echo "[+] Getting latest tcp / udp port numbers"
  wget -N -q https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.csv
  cd ..
fi

# TLD Info
if [ ! -f tlds-alpha-by-domain.txt ]; then
  echo "[+] Getting latest TLDs"
  wget -N -q http://data.iana.org/TLD/tlds-alpha-by-domain.txt
fi

# public suffix info
if [ ! -f public_suffix_list.dat ]; then
  echo "[+] Getting latest Public suffix list"
  wget -N -q https://publicsuffix.org/list/public_suffix_list.dat
  cat public_suffix_list.dat | grep -i -e '^/' -v | awk 'NF' | sed 's/\*\.//g' > public_suffix_list.clean.txt
  rm public_suffix_list.dat
fi

# NVD feeds
NVD_YEARS="2019 2018 2017"

# nvd download function
function get_nvd_json() {
  echo "[+] Getting latest NVD JSON Feed: $YEAR"
  wget -N -q https://nvd.nist.gov/feeds/json/cve/1.0/nvdcve-1.0-$YEAR.json.gz -O nvdcve-1.0-$YEAR.json.gz
  gunzip nvdcve-1.0-$YEAR.json.gz
}

if [ -d "nvd" ]; then
  echo "[ ] Cleaning NVD directory"
  rm -rf nvd
fi

# check and download
for YEAR in $NVD_YEARS; do

  mkdir -p nvd
  cd nvd
    get_nvd_json $YEAR
  cd ..

done

echo "[+] Data Update Complete!"


