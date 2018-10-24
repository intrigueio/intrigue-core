# simplify getting nvd feeds
NVD_YEARS="2018 2017 2016 2015 2014 2013 2012 2011"

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