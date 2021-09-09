#!/bin/bash

#####
##### SYSTEM SOFTWARE INSTALLATION
#####

# if these are already set by our parent, use that.. otherwise sensible defaults
if [ "$1" == "development" ]; then
  echo "Dev Bootstrap Starting!";
  BOOTSTRAP_ENV=development
else
  echo "Production Bootstrap Starting!";
  BOOTSTRAP_ENV=production
fi

export INTRIGUE_DIRECTORY="${IDIR:=/home/$USER/core}"
export RUBY_VERSION="${RUBY_VERSION:=2.7.2}"
export DEBIAN_FRONTEND=noninteractive

# Clean up
echo "[+] Ensuring Apt is clean"
sudo apt-get -y autoremove
sudo apt-get --purge remove
sudo apt-get -y autoclean
sudo apt-get -y clean

echo "[+] Updating Apt"
sudo apt-get update --fix-missing

# UPGRADE FULLY NON-INTERACTIVE
echo "[+] Preparing the System by upgrading"
sudo DEBIAN_FRONTEND=noninteractive \
  apt-get -y -o \
  DPkg::options::="--force-confdef" -o \
  DPkg::options::="--force-confold" \
  upgrade grub-pc

echo "[+] Reconfigure Dpkg"
sudo dpkg --configure -a

echo "[+] Installing Apt Essentials"
sudo apt-get -y install tzdata wget
sudo apt-get -y install lsb-core software-properties-common dirmngr apt-transport-https lsb-release ca-certificates locales apt-utils

echo "[+] Adding Golang Apt repo"
sudo add-apt-repository --yes ppa:longsleep/golang-backports

echo "[+] Adding Chromium repo"
sudo add-apt-repository --yes ppa:saiarcot895/chromium-dev

echo "[+] Adding Postgres Apt repo"
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" |sudo tee  /etc/apt/sources.list.d/pgdg.list

echo "[+] Updating Apt with new repos"
sudo apt-get update --fix-missing

# set locales to UTF-8
sudo sh -c 'echo "LC_ALL=en_US.UTF-8" >> /etc/environment'
sudo sh -c 'echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen'
sudo sh -c 'echo "LANG=en_US.UTF-8" > /etc/locale.conf'
sudo locale-gen en_US.UTF-8
echo "export LANG=en_US.UTF-8" >> $HOME/.bash_profile

# just in case, do the fix-broken flag
echo "[+] Installing Intrigue Dependencies..."
sudo apt-get -y --no-install-recommends install make \
  git \
  git-core \
  zip \
  bzip2 \
  autoconf \
  bison \
  build-essential \
  apt-utils \
  software-properties-common \
  lsb-release \
  libssl-dev \
  libyaml-dev \
  libreadline6-dev \
  zlib1g-dev \
  libncurses5-dev \
  libffi-dev \
  libsqlite3-dev \
  net-tools \
  redis-server \
  boxes \
  nmap \
  zmap \
  default-jre \
  thc-ipv6 \
  unzip \
  curl \
  git \
  gcc \
  make \
  libpcap-dev \
  fontconfig \
  locales \
  gconf-service \
  libasound2 \
  libatk1.0-0 \
  libc6 \
  libcairo2 \
  libcups2 \
  libdbus-1-3 \
  libexpat1 \
  libfontconfig1 \
  libgcc1 \
  libgconf-2-4 \
  libgdk-pixbuf2.0-0 \
  libglib2.0-0 \
  libgtk-3-0 \
  libnspr4 \
  libpango-1.0-0 \
  libpangocairo-1.0-0 \
  libstdc++6 \
  libx11-6 \
  libx11-xcb1 \
  libxcb1 \
  libxcomposite1 \
  libxcursor1 \
  libxdamage1 \
  libxext6 \
  libxfixes3 \
  libxi6 \
  libxrandr2 \
  libxrender1 \
  libxss1 \
  libxtst6 \
  ca-certificates \
  fonts-liberation \
  fonts-thai-tlwg \
  libappindicator1 \
  libnss3 \
  lsb-release \
  xdg-utils \
  systemd \
  tcptraceroute \
  wget \
  python3-minimal \
  golang-go \
  postgresql-12 \
  postgresql-client-12 \
  postgresql-server-dev-12 \
  postgresql-12-repack \
  libpq-dev \
  xvfb \
  libwebkit2gtk-4.0-37

# Support older TLS ciphers
sudo apt -y remove libcurl4
sudo apt -y install libcurl4-gnutls-dev

# NOTE! for whatever reason, this has to be with apt vs apt-get
sudo apt -y install chromium-browser

echo "[+] Creating a home for binaries"
mkdir -p $HOME/bin
export BINPATH=$HOME/bin
export PATH=$PATH:$BINPATH
# and for later
echo "export PATH=$PATH:$BINPATH" >> $HOME/.bash_profile

# dnsmorph
echo "[+] Getting DNSMORPH binaries... "
cd $BINPATH
wget -q https://github.com/netevert/dnsmorph/releases/download/v1.2.7/dnsmorph_1.2.7_linux_64-bit.tar.gz
tar -zxvf dnsmorph_1.2.7_linux_64-bit.tar.gz
chmod +x dnsmorph
rm dnsmorph_1.2.7_linux_64-bit.tar.gz
cd $HOME

# Go is added via apt
# ensure we have the path
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
# and for later
echo export GOPATH=$HOME/go >> ~/.bash_profile
echo export PATH=$PATH:$GOPATH/bin >> ~/.bash_profile

# ffuf
echo "[+] Getting Ffuf... "
GO111MODULE=on go get -u -v github.com/ffuf/ffuf

# gitrob
echo "[+] Getting Gitrob... "
cd $HOME/bin
wget -q https://github.com/codeEmitter/gitrob/releases/download/v3.4.1-beta/gitrob_linux_amd64_3.4.1-beta.zip
unzip gitrob_linux_amd64_3.4.1-beta.zip
chmod +x gitrob
mkdir data
mkdir data/gitrob
mv *.json data/gitrob
rm gitrob_linux_amd64_3.4.1-beta.zip README.md
cd $HOME

# gitleaks
echo "[+] Getting Gitleaks... "
GO111MODULE=on go get github.com/zricethezav/gitleaks/v7

# jarmscan
echo "[+] Getting Jarmscan... "
cd $HOME/bin
wget -q https://github.com/RumbleDiscovery/jarm-go/releases/download/v0.0.5/jarm-go_0.0.5_Linux_x86_64.tar.gz
tar xzf jarm-go_0.0.5_Linux_x86_64.tar.gz
chmod +x jarmscan
rm jarm-go_0.0.5_Linux_x86_64.tar.gz LICENSE.txt
cd $HOME

# gobuster
echo "[+] Getting Gobuster... "
go get github.com/OJ/gobuster

# ghostcat
echo "[+] Getting Ghostcat Vuln... "
go get github.com/intrigueio/tomcat-cve-2020-1938-check

# masscan
echo "[+] Installing Masscan"
if [ ! -f /usr/bin/masscan ]; then
  git clone https://github.com/robertdavidgraham/masscan
  cd masscan
  make
  sudo make install
  cd ..
  rm -rf masscan
fi

# naabu
echo "[+] Getting Naabu... "
GO111MODULE=on go get -v github.com/projectdiscovery/naabu/v2/cmd/naabu
# rdpscan
echo "[+] Installing Rdpscan"
if [ ! -f /usr/bin/rdpscan ]; then
  git clone https://github.com/robertdavidgraham/rdpscan
  cd rdpscan
  make
  sudo cp rdpscan /usr/bin
  cd ..
  rm -rf rdpscan
fi

# for rdp screenshots
echo "[+] Getting Scrying... "
wget https://github.com/nccgroup/scrying/releases/download/v0.9.0-alpha.2/scrying_0.9.0-alpha.2_amd64.deb
sudo dpkg -i scrying_0.9.0-alpha.2_amd64.deb
rm scrying_0.9.0-alpha.2_amd64.deb

# subfinder
GO111MODULE=on go get -u -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder

### Install latest tika
echo "[+] Installing Apache Tika from public.intrigue.io"
LATEST_TIKA_VERSION=1.24.1
cd $INTRIGUE_DIRECTORY/tmp
mkdir -p $INTRIGUE_DIRECTORY/tmp/
wget -q https://s3.amazonaws.com/public.intrigue.io/tika-server-$LATEST_TIKA_VERSION.jar
mv $INTRIGUE_DIRECTORY/tmp/tika-server-$LATEST_TIKA_VERSION.jar $INTRIGUE_DIRECTORY/tmp/tika-server.jar
cd $HOME

# update sudoers
echo "[+] Updating Sudo configuration"
if ! sudo grep -q NMAP /etc/sudoers; then
  echo "[+] Configuring sudo for nmap, masscan, rdpscan"
  echo "Cmnd_Alias NMAP = /usr/bin/nmap" | sudo tee --append /etc/sudoers
  echo "Cmnd_Alias MASSCAN = /usr/bin/masscan" | sudo tee --append /etc/sudoers
  echo "Cmnd_Alias RDPSCAN = /usr/bin/rdpscan" | sudo tee --append /etc/sudoers
  echo "%admin ALL=(root) NOPASSWD: MASSCAN, NMAP, RDPSCAN" | sudo tee --append /etc/sudoers
else
  echo "[+] nmap, masscan already configured to run as sudo"
fi

# bump file limits
echo "bumping file-max settings"
sudo bash -c "echo fs.file-max = 655355 >> /etc/sysctl.conf"

# enable heuristic memory overcommit
echo "enable memory overcommit"
sudo bash -c "echo vm.overcommit_memory=0 >> /etc/sysctl.conf"
sudo sysctl -p

echo "Bumping ulimit file/proc settings in /etc/security/limits.conf"
sudo bash -c "echo 'root hard nofile 524288' >> /etc/security/limits.conf"
sudo bash -c "echo 'root soft nofile 524288' >> /etc/security/limits.conf"
sudo bash -c "echo 'root hard nproc 524288' >> /etc/security/limits.conf"
sudo bash -c "echo 'root soft nproc 524288' >> /etc/security/limits.conf"
sudo bash -c "echo '* hard nproc 524288' >> /etc/security/limits.conf"
sudo bash -c "echo '* soft nproc 524288' >> /etc/security/limits.conf"
sudo bash -c "echo '* hard nofile 524288' >> /etc/security/limits.conf"
sudo bash -c "echo '* soft nofile 524288' >> /etc/security/limits.conf"
sudo bash -c "echo session required pam_limits.so >> /etc/pam.d/common-session"

# Set the database to trust
echo "[+] Updating postgres configuration"
sudo service postgresql stop
sudo sed -i 's/md5/trust/g' /etc/postgresql/*/main/pg_hba.conf
sudo sed -i 's/peer/trust/g' /etc/postgresql/*/main/pg_hba.conf

echo "[+] Creating clean database"
sudo service postgresql start
sudo -u postgres createuser intrigue
sudo -u postgres createdb intrigue_dev --owner intrigue

##### Install rbenv
if [ ! -d ~/.rbenv ]; then
  echo "[+] Installing & Configuring rbenv"

  git clone https://github.com/rbenv/rbenv.git ~/.rbenv
  cd ~/.rbenv && src/configure && make -C src
  echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
  echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
  source ~/.bash_profile > /dev/null

  # manually load it up...
  eval "$(rbenv init -)"
  export PATH="$HOME/.rbenv/bin:$PATH"
  # for later
  echo export PATH="$HOME/.rbenv/bin:$PATH" >> ~/.bash_profile

  # ruby-build
  mkdir -p ~/.rbenv/plugins
  git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
  # rbenv gemset
  git clone git://github.com/jf/rbenv-gemset.git ~/.rbenv/plugins/rbenv-gemset
else
  echo "[+] rbenv installed, upgrading..."
  # upgrade rbenv
  cd ~/.rbenv && git pull
  # upgrade rbenv-root
  cd ~/.rbenv/plugins/ruby-build && git pull
  # upgrade rbenv-root
  cd ~/.rbenv/plugins/rbenv-gemset && git pull
fi

# setup ruby
if [ ! -e ~/.rbenv/versions/$RUBY_VERSION ]; then
  echo "[+] Installing Ruby $RUBY_VERSION"
  rbenv install $RUBY_VERSION
  export PATH="$HOME/.rbenv/versions/$RUBY_VERSION:$PATH"
else
  echo "[+] Using Ruby $RUBY_VERSION"
fi

source ~/.bash_profile > /dev/null
rbenv global $RUBY_VERSION
echo "Ruby version: `ruby -v`"

# Install bundler
echo "[+] Installing Latest Bundler"
gem install bundler:2.1.4 --no-document
rbenv rehash

#####
##### INTRIGUE SETUP / CONFIGURATION
#####
echo "[+] Installing Gem Dependencies"
cd $INTRIGUE_DIRECTORY
bundle update --bundler
bundle install

# Cleaning up
echo "[+] Cleaning up packages!"
sudo apt-get -y clean

###
### Only in production should we continue on to do this
###
if [ "$BOOTSTRAP_ENV" == "production" ] && [ !$(grep -q intriguectl ~/.bash_profile) ]; then

  echo "echo \"Welcome to Intrigue Core! For help, join the community at https://core.intrigue.io\"" >> ~/.bash_profile
  echo "echo \"\"" >> ~/.bash_profile

  # add welcome message
  echo "[+] Adding intrigue to path"
  ln -s ~/core/util/intriguectl ~/go/bin/intriguectl 2> /dev/null

  # always tell the user they have intriguectl
  echo "intriguectl" >> ~/.bash_profile

else
  echo "echo \"CORE DEVELOPMENT ENVIRONMENT! Use foreman to manage services!\"" >> ~/.bash_profile
fi

