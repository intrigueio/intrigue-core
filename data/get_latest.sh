#!/bin/bash

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

# tika 
if [ ! -f ../tmp/tika-server.jar ]; then
  echo "[+] Getting Tika"
  wget -N -q https://apache.osuosl.org/tika/tika-server-1.25.jar -O ../tmp/tika-server.jar
fi

# retirejs data 
if [ ! -f retirejs.json ]; then
  echo "[+] Getting latest Retire.js"
  wget -N -q https://raw.githubusercontent.com/pentestify/retire.js/master/repository/jsrepository.json 
  mv jsrepository.json retirejs.json
fi

# NVD feeds
NVD_YEARS="2021 2020 2019 2018 2017"

# nvd download function
function get_nvd_json() {
  echo "[+] Getting latest NVD JSON Feed: $YEAR"
  wget -N -q https://nvd.nist.gov/feeds/json/cve/1.1/nvdcve-1.1-$YEAR.json.gz -O nvdcve-1.1-$YEAR.json.gz
  gunzip nvdcve-1.1-$YEAR.json.gz
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

if [ ! -d "nuclei-templates"  ]; then
  echo "[+] Getting nuclei templates"
  git clone https://github.com/projectdiscovery/nuclei-templates 2> /dev/null
else
  echo "[+] Updating nuclei templates"
  cd nuclei-templates
  git pull 2> /dev/null
  cd ..
fi


echo "[+] Data Update Complete!"


