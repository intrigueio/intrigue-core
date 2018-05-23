export INTRIGUE_DIRECTORY="/core"

#####
##### SYSTEM SETUP / CONFIG
#####

echo "[+] Preparing the system"
##### Add external repositories
sudo add-apt-repository "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -sc)-pgdg main"
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

##### Update the system
sudo apt-get -y update
sudo apt-get -y upgrade

##### Install all the base dependencies
sudo apt-get -y install libpq-dev postgresql-9.6 postgresql-server-dev-9.6 redis-server

## MOTD
sudo apt-get install boxes

##### Scanning
sudo apt-get -y install nmap zmap

##### Install masscan
if [ ! -f /usr/bin/masscan ]; then
  sudo apt-get -y install git gcc make libpcap-dev
  git clone https://github.com/robertdavidgraham/masscan
  cd masscan
  make
  sudo make install
fi

##### Java
sudo apt-get -y install default-jre

##### Install Thc-ipv6
sudo apt-get -y install thc-ipv6

##### Install ImageMagick
sudo apt-get -y install gcc build-essential chrpath libssl-dev libxft-dev libfreetype6-dev
sudo apt-get -y install libfreetype6 libfontconfig1-dev libfontconfig1 imagemagick
sudo apt-get -y install libreadline-dev libsqlite3-dev

##### Install PhantomJS
if [ ! -f /usr/local/bin/phantomjs ]; then
  wget -q https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2
  sudo tar xvjf phantomjs-2.1.1-linux-x86_64.tar.bz2 -C /usr/local/share/
  sudo ln -s /usr/local/share/phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/local/bin/
fi

echo "[+] Creating Database"
sudo -u postgres createuser intrigue
sudo -u postgres createdb intrigue_dev --owner intrigue

# Set the database to trust
sudo sed -i 's/md5/trust/g' /etc/postgresql/9.6/main/pg_hba.conf
sudo service postgresql restart

##### Install rbenv

if [ ! -d ~/.rbenv ]; then
  echo "[+] Configuring rbenv"
  git clone https://github.com/rbenv/rbenv.git ~/.rbenv
  cd ~/.rbenv && src/configure && make -C src
  echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
  echo 'eval "$(rbenv init -)"' >> ~/.bashrc

  # ruby-build
  mkdir -p ~/.rbenv/plugins
  git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build

  # rbenv gemset
  git clone git://github.com/jf/rbenv-gemset.git ~/.rbenv/plugins/rbenv-gemset

  # rbenv sudo
  git clone git://github.com/dcarley/rbenv-sudo.git ~/.rbenv/plugins/rbenv-sudo

else

  # upgrade rbenv
  cd ~/.rbenv && git pull
  # upgrade rbenv-root
  cd ~/.rbenv/plugins/ruby-build && git pull
  # upgrade rbenv-root
  cd ~/.rbenv/plugins/rbenv-gemset && git pull
  # upgrade rbenv-sudo
  cd ~/.rbenv/plugins/rbenv-sudo && git pull

fi

# make sure rbenv is in our path
export PATH="$HOME/.rbenv/bin:$PATH"
source ~/.bashrc

RUBY_VERSION=`cat $INTRIGUE_DIRECTORY/.ruby-version`
if [ ! -e ~/.rbenv/versions/$RUBY_VERSION ]; then
  echo "[+] Installing Ruby $RUBY_VERSION"
  rbenv install $RUBY_VERSION
  rbenv global $RUBY_VERSION
fi

if [ ! -e ~/.rbenv/shims/bundle ]; then
  gem install bundler
  rbenv rehash
fi

#####
##### INTRIGUE SETUP / CONFIGURATION
#####
cd $INTRIGUE_DIRECTORY
bundle install

echo "[+] Migrating database"
bundle exec rake db:migrate

if [ ! -f /etc/init.d/intrigue ]; then
  echo "[+] Creating intrigue service"
  sudo cp $INTRIGUE_DIRECTORY/util/intrigue.service /lib/systemd/system
  sudo chmod +x $INTRIGUE_DIRECTORY/util/control.sh
fi

echo "source ~/.bashrc && boxes -a c -d unicornthink /core/util/instructions" > .bash_profile

# run the service
rbenv sudo $INTRIGUE_DIRECTORY/util/control.sh start
