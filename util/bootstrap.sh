#!/bin/bash

# if these are already set by our parent, use that.. otherwise sensible defaults
export INTRIGUE_DIRECTORY="${INTRIGUE_DIRECTORY:=/core}"
export RUBY_VERSION="${RUBY_VERSION:=2.5.1}"

#####
##### SYSTEM SETUP / CONFIG
#####

# Clean up apt
#echo "[+] Cleaning apt locks"
#sudo rm /var/lib/apt/lists/lock
#sudo rm /var/cache/apt/archives/lock
#sudo rm /var/lib/dpkg/lock

# UPGRADE FULLY NON-INTERACTIVE
#echo "[+] Preparing the System"
#sudo DEBIAN_FRONTEND=noninteractive \
#	apt-get -y -o \
#	DPkg::options::="--force-confdef" -o \
#	DPkg::options::="--force-confold" \
#	upgrade

# UPGRADE FULLY NON-INTERACTIVE
# See: https://askubuntu.com/questions/146921/how-do-i-apt-get-y-dist-upgrade-without-a-grub-config-prompt
#sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o DPkg::options::="--force-confdef" -o DPkg::options::="--force-confold" install grub-pc
#sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade

echo "[+] Installing System Essentials"
sudo apt-get -y install git git-core bzip2 autoconf bison build-essential apt-utils software-properties-common lsb-release sudo wget make

##### Add external repositories
# chrome repo
echo "[+] Adding 3rd Party Repos"
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
# postgres repo
sudo add-apt-repository "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -sc)-pgdg main"
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

##### Install postgres, redis
echo "[+] Updating from Third Party Reposoitories ..."
sudo apt-get -y update
sudo apt-get -y upgrade

echo "[+] Installing Intrigue Dependencies..."
sudo apt-get -y install libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libsqlite3-dev net-tools libpq-dev postgresql-9.6 postgresql-server-dev-9.6 redis-server boxes nmap zmap default-jre thc-ipv6 unzip curl git gcc make libpcap-dev

echo "[+] Installing Google Chrome Headless dependencies"
sudo apt-get -y update && sudo apt-get install -y \
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
  google-chrome-stable

# Get dumb-init
#echo "[+] Installing dumb-init"
#if [ ! -f /usr/bin/dumb-init ]; then
#  mkdir dumb-init
#  cd dumb-init
#  wget -q "https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64"
#  sudo cp dumb-init_1.2.0_amd64 /usr/bin/dumb-init
#  sudo chmod +x /usr/bin/dumb-init
#  cd ..
#  rm -rf dumb-init
#fi

#####  Install golang & gitrob
echo "[+] Installing Golang"
sudo apt-get -y install golang-go

# add go vars (and note that we source this file later as well)
echo "[+] Installing Golang environment"
echo export GOPATH=$HOME/go >> ~/.bash_profile
echo export PATH=$PATH:$GOROOT/bin:$GOPATH/bin >> ~/.bash_profile
source ~/.bash_profile > /dev/null

# get the code
echo "[+] Getting Gitrob"
go get github.com/intrigueio/gitrob

##### Install masscan
echo "[+] Installing Masscan"
if [ ! -f /usr/bin/masscan ]; then
  git clone https://github.com/robertdavidgraham/masscan
  cd masscan
  make
  sudo make install
  cd ..
  rm -rf masscan
fi

# Get chromedriver
echo "[+] Installing Chromedriver"
if [ ! -f /usr/bin/chromedriver ]; then
  mkdir chromedriver
  cd chromedriver
  CHROMEDRIVER_VERSION=`wget -q -O - "http://chromedriver.storage.googleapis.com/LATEST_RELEASE"`
  wget -q "http://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip"
  unzip chromedriver_linux64.zip
  sudo cp chromedriver /usr/bin/chromedriver
  sudo chmod +x /usr/bin/chromedriver
  cd ..
  rm -rf chromedriver
fi

# update sudoers
echo "[+] Updating Sudo configuration"
if ! sudo grep -q NMAP /etc/sudoers; then
  echo "[+] Configuring sudo for nmap, masscan"
  echo "Cmnd_Alias NMAP = /usr/local/bin/nmap" | sudo tee --append /etc/sudoers
  echo "Cmnd_Alias MASSCAN = /usr/local/bin/masscan" | sudo tee --append /etc/sudoers
  echo "%admin ALL=(root) NOPASSWD: NMAP, MASSCAN" | sudo tee --append /etc/sudoers
else
  echo "[+] nmap, masscan already configured to run as sudo"
fi

# bump file limits
echo "Bumping ulimit settings"
sudo bash -c "echo * soft nofile 16384 >> /etc/security/limits.conf"
sudo bash -c "echo * hard nofile 16384 >> /etc/security/limits.conf"

# Set the database to trust
echo "[+] Updating postgres configuration"
sudo sed -i 's/md5/trust/g' /etc/postgresql/9.6/main/pg_hba.conf
sudo service postgresql restart

echo "[+] Creating database"
sudo -u postgres createuser intrigue
sudo -u postgres createdb intrigue_dev --owner intrigue

##### Install rbenv
if [ ! -d ~/.rbenv ]; then
  echo "[+] Configuring rbenv"
  git clone https://github.com/rbenv/rbenv.git ~/.rbenv
  cd ~/.rbenv && src/configure && make -C src
  echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
  echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
  source ~/.bash_profile > /dev/null
  # manually load it up... for docker
  eval "$(rbenv init -)"
  export PATH="$HOME/.rbenv/bin:$PATH"
  # ruby-build
  mkdir -p ~/.rbenv/plugins
  git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
  # rbenv gemset
  git clone git://github.com/jf/rbenv-gemset.git ~/.rbenv/plugins/rbenv-gemset
else
  echo "[+] Upgrading rbenv"
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
echo "[+] Installing Bundler"
gem install bundler --no-ri --no-rdoc
rbenv rehash

#####
##### INTRIGUE SETUP / CONFIGURATION
#####
echo "[+] Installing Gem Dependencies"
cd $INTRIGUE_DIRECTORY
bundle install

echo "[+] Running System Setup"
bundle exec rake setup

echo "[+] Running DB Migrations"
bundle exec rake db:migrate

echo "[+] Configuring puma to listen on 0.0.0.0"
sed -i "s/tcp:\/\/127.0.0.1:7777/tcp:\/\/0.0.0.0:7777/g" $INTRIGUE_DIRECTORY/config/puma.rb

echo "[+] Configuring puma to daemonize"
sed -i "s/daemonize false/daemonize true/g" $INTRIGUE_DIRECTORY/config/puma.rb

if [ ! -f /etc/init.d/intrigue ]; then
  echo "[+] Creating Intrigue system service"
  sudo cp $INTRIGUE_DIRECTORY/util/intrigue.service /lib/systemd/system
  sudo chmod +x $INTRIGUE_DIRECTORY/util/control.sh
fi

if ! $(grep -q README ~/.bash_profile); then
  echo "[+] Configuring startup message"
  echo "boxes -a c -d unicornthink $INTRIGUE_DIRECTORY/util/README" >> ~/.bash_profile
fi

# if we're configuring as root, we're probably going to run as root, so
#   manually force the .bash_profile to be run every login
if [ $(id -u) = 0 ]; then
   echo "source ~/.bash_profile" >> ~/.bashrc
fi

# Handy for future, given this may differ across platforms
if ! $(grep -q INTRIGUE_DIRECTORY ~/.bash_profile); then
  echo "export INTRIGUE_DIRECTORY=$INTRIGUE_DIRECTORY" >> ~/.bash_profile
fi

# Cleaning up
echo "[+] Cleaning up!"
sudo apt-get -y clean
