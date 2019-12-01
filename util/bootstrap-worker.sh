#!/bin/bash

#####
##### SYSTEM SOFTWARE INSTALLATION
#####

# if these are already set by our parent, use that.. otherwise sensible defaults
export INTRIGUE_DIRECTORY="${IDIR:=//home/ubuntu/core}"
export RUBY_VERSION="${RUBY_VERSION:=2.6.5}"
export DEBIAN_FRONTEND=noninteractive

# Clean up
echo "[+] Ensuring Apt is clean"
sudo apt-get autoremove
sudo apt-get --purge remove
sudo apt-get autoclean
sudo apt-get clean
sudo apt-get update --fix-missing
echo "[+] Proceeding with system setup"

# UPGRADE FULLY NON-INTERACTIVE
echo "[+] Preparing the System by upgrading"
sudo DEBIAN_FRONTEND=noninteractive \
  apt-get -y -o \
  DPkg::options::="--force-confdef" -o \
  DPkg::options::="--force-confold" \
  upgrade grub-pc dist-upgrade

echo "[+] Reconfigure Dpkg"
sudo dpkg --configure -a

echo "[+] Installing Apt Essentials"
sudo apt-get -y install tzdata wget
sudo apt-get -y install lsb-core software-properties-common dirmngr apt-transport-https lsb-release ca-certificates locales

##### Add external repositories

# chrome repo
echo "[+] Installing Chromium"
#sudo apt-get install software-properties-common
sudo add-apt-repository ppa:canonical-chromium-builds/stage
sudo apt-get update
sudo apt-get -y install chromium-browser
##### Install dependencies after update

# set locales
echo "LC_ALL=en_US.UTF-8" >> /etc/environment
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
locale-gen en_US.UTF-8

# just in case, do the fix-broken flag
echo "[+] Installing Intrigue Dependencies..."
sudo apt-get -y --fix-broken --no-install-recommends install make \
  git \
  git-core \
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
  libpq-dev \
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
  golang-go \
  dnsmasq \
  systemd \
  python-minimal &&
  rm -rf /var/lib/apt/lists/*

echo "[+] Creating a home for binaries"
mkdir -p $HOME/bin
export BINPATH=$HOME/bin
export PATH=$PATH:$BINPATH
# and for latere
echo export PATH=$PATH:$BINPATH ~/.bash_profile

# dnsmorph
echo "[+] Getting DNSMORPH binaries... "
cd $BINPATH
wget https://github.com/netevert/dnsmorph/releases/download/v1.2.7/dnsmorph_1.2.7_linux_64-bit.tar.gz
tar -zxvf dnsmorph_1.2.7_linux_64-bit.tar.gz
chmod +x dnsmorph
rm dnsmorph_1.2.7_linux_64-bit.tar.gz
cd $HOME

# add go vars (and note that we source this file later as well)
echo "[+] Installing Golang environment"

# ensure we have the path
export GOPATH=$HOME/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin

# and for later
echo export GOPATH=$HOME/go >> ~/.bash_profile
echo export PATH=$PATH:$GOROOT/bin:$GOPATH/bin >> ~/.bash_profile

# gitrob
echo "[+] Getting Gitrob... "
go get github.com/intrigueio/gitrob

# gobuster
echo "[+] Getting Gobuster... "
go get github.com/intrigueio/gobuster.git

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

### Install latest tika
echo "[+] Installing Apache Tika"
cd $INTRIGUE_DIRECTORY/tmp
LATEST_TIKA_VERSION=1.22
wget http://apache-mirror.8birdsvideo.com/tika/tika-server-$LATEST_TIKA_VERSION.jar
cd $HOME

# update sudoers
echo "[+] Updating Sudo configuration"
if ! sudo grep -q NMAP /etc/sudoers; then
  echo "[+] Configuring sudo for nmap, masscan, rdpscan"
  echo "Cmnd_Alias NMAP = /usr/local/bin/nmap" | sudo tee --append /etc/sudoers
  echo "Cmnd_Alias MASSCAN = /usr/local/bin/masscan" | sudo tee --append /etc/sudoers
  echo "Cmnd_Alias RDPSCAN = /usr/local/bin/rdpscan" | sudo tee --append /etc/sudoers
  echo "%admin ALL=(root) NOPASSWD: MASSCAN, NMAP, RDPSCAN" | sudo tee --append /etc/sudoers
else
  echo "[+] nmap, masscan already configured to run as sudo"
fi

# bump file limits
echo "bumping file-max setting"
sudo bash -c "echo fs.file-max = 65535 >> /etc/sysctl.conf"
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

##### Install rbenv
echo "[+] Installing & Configuring rbenv"
if [ ! -d ~/.rbenv ]; then

  git clone https://github.com/rbenv/rbenv.git ~/.rbenv
  cd ~/.rbenv && src/configure && make -C src
  echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
  echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
  source ~/.bash_profile > /dev/null

  # manually load it up...
  eval "$(rbenv init -)"
  export PATH="$HOME/.rbenv/bin:$PATH"
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
gem install bundler:2.0.2 --no-document
rbenv rehash

#####
##### INTRIGUE SETUP / CONFIGURATION
#####
echo "[+] Installing Gem Dependencies"
cd $INTRIGUE_DIRECTORY
bundle update --bundler
bundle install

echo "[+] Running System Setup"
bundle exec rake setup

echo "[+] Running DB Migrations"
bundle exec rake db:migrate

# TOOD ... remove this on next major release
echo "[+] Intrigue services exist, removing... (ec2 legacy)"
if [ ! -f /etc/init.d/intrigue ]; then
  rm -rf /etc/init.d/intrigue
fi

if ! $(grep -q README ~/.bash_profile); then
  echo "[+] Configuring startup message"
  echo "boxes -a c $INTRIGUE_DIRECTORY/util/README" >> ~/.bash_profile
fi

### HANDLE DOCKER STUFF HERE
if [ -f /.dockerenv ]; then
  echo "[+] I'm inside docker, i can start services automatically!";
else
  echo "[+] Nooooo I'm not inside docker!";
  echo "echo ''" >> ~/.bash_profile
  echo "echo To enable Intrigue services, run the following command:" >> ~/.bash_profile
  echo "echo '$ cd core && god -c $INTRIGUE_DIRECTORY/util/god/intrigue-ec2.rb && god start'" >> ~/.bash_profile
fi

# if we're configuring as root, we're probably going to run as root, so
#   manually force the .bash_profile to be run every login
if [ $(id -u) = 0 ]; then
   echo "source ~/.bash_profile" >> ~/.bashrc
fi

# Handy for future, given this may differ across platforms
if ! $(grep -q IDIR ~/.bash_profile); then
  echo "export IDIR=$INTRIGUE_DIRECTORY" >> ~/.bash_profile
fi

# Cleaning up
echo "[+] Cleaning up!"
sudo apt-get -y clean
