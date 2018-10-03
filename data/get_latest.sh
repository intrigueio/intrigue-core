#!/bin/bash

# GeoLiteCity download function
function get_maxmind() {
  echo "[+] Getting latest MaxMind GeoLiteCity database"
  wget -N -q  http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz
  gunzip GeoLiteCity.dat.gz
  mv GeoLiteCity.dat latest.dat
}

# GeoLiteCity
if [ -d "geolitecity" ]; then
  cd geolitecity
  if [ ! -f geolitecity/latest.dat ]; then
    get_maxmind
  else
    echo "[+] Moving old MaxMind GeoLiteCity database"
    mv latest.dat latest.dat.old
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
  cd ..
fi

# ASN Info
# https://www.quaxio.com/bgp/
if [ -d "asn_info" ]; then
  cd asn_info
  echo "[+] Getting latest ASN data from APNIC"
  wget -N -q http://thyme.apnic.net/current/data-raw-table
  wget -N -q http://thyme.apnic.net/current/data-used-autnums
  cd ..
fi

#if [ -d "alexa" ]; then
#  echo "Getting latest Alexa database"
#  cd alexa
#  wget -N -q http://s3.amazonaws.com/alexa-static/top-1m.csv.zip
#  unzip top-1m.csv.zip
#  mv top-1m.csv latest.csv
#  rm top-1m.csv.zip
#  cd ..
#fi

# TLD Info
if [ ! -f tlds-alpha-by-domain.txt ]; then
  echo "[+] Getting latest TLDs"
  wget -N -q http://data.iana.org/TLD/tlds-alpha-by-domain.txt
fi

# public suffix info
if [ ! -f public_suffix_list.dat ]; then
  echo "[+] Getting latest Public Suffix list"
  wget -N -q https://publicsuffix.org/list/public_suffix_list.dat
  cat public_suffix_list.dat | grep -i -e '^/' -v | awk 'NF' | sed 's/\*\.//g' > public_suffix_list.clean.txt
  rm public_suffix_list.dat
fi


