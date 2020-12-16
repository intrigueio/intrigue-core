#! /bin/bash

# Set path to include rbenv
source $HOME/.bash_profile

# print our welcome message
Welcome()
{
  echo "/****************************************************************************************/"
  echo "/*                              Welcome to Intrigue Core!                               */"
  echo "/*                                                                                      */"
  echo "/* Please file bugs & requests here: https://github.com/intrigueio/intrigue-core/issues */"
  echo "/*                                                                                      */"
  echo "/*                 Other comments? Questions? Email hello@intrigue.io.                  */"
  echo "/****************************************************************************************/"
}


Help()
{
    # Display Help
    echo "Intrigue Core Management Script"
    echo
    echo "Syntax: ./intriguectl [start|stop|setup]"
    echo "options:"
    echo "setup   initialize intrigue services."
    echo "start   start intrigue services"
    echo "stop    stop intrigue services"
    echo
    echo "To set your basic auth password, export variable CORE_PASSWD and (re)run setup"
    echo
}

SetPassword()
{
    if [ "${CORE_PASSWD}" ]; then
      FILE1=~/core/config/config.json
      FILE2=~/core/config/config.json.default
      if [ -f "$FILE1" ]; then
          sed -i "s/\"password\": \".*\"/\"password\": \"${CORE_PASSWD}\"/g" $FILE1
      elif [ -f "$FILE2" ]; then
          sed -i "s/\"password\": \".*\"/\"password\": \"${CORE_PASSWD}\"/g" $FILE2
      else
          echo "[!] Failed to set basic auth password. Check that your installation is in your home directory"
      fi
    fi
    
}

Setup()
{
    # check if we are a worker (we don't need to setup database if we are)
    if [ "${WORKER_CONFIG}" ]; then
      echo "[+] We are a worker-only configuration!"
      return
    fi 
    
    # set password
    SetPassword

    # Set up database if it's not already there 
    if [ ! -d /data/postgres ]; then
      echo "[+] Configuring postgres..."
      sudo service postgresql stop
      sudo mkdir -p /data/postgres
      sudo chown postgres:postgres /data/postgres 
      sudo -u postgres /usr/lib/postgresql/*/bin/initdb /data/postgres 
      sudo service postgresql start
    fi 

    # force user/db creation, just in case
    sudo -u postgres createuser intrigue 2> /dev/null
    sudo -u postgres createdb intrigue_dev --owner intrigue 2> /dev/null

    # Adjust and spin up redis
    if [ ! -d /data/redis ]; then
      echo "[+] Configuring redis..."
      sudo service redis-server stop
      sudo mkdir -p /data/redis
      sudo chown redis:redis /data/redis
      sudo service redis-server start
      sudo systemctl daemon-reload
    fi

    # change to core's directory
    cd ~/core

    # run setup
    echo "[+] Setting up Intrigue standalone..."
    bundle exec rake setup
    
    # migrade db
    echo "[+] Migrating Database..."
    bundle exec rake db:migrate

    # configure god
    god -c ~/core/util/god/intrigue.rb
    
    echo "[+] Setup complete!"
}

################################################################################
################################################################################
# Main program                                                                 #
################################################################################
################################################################################
Welcome

cmd=$1

if [ -z "$cmd" ];
then
    Help
    exit
fi

if [ "$cmd" == "start" ]; then
    echo "[+] Starting intrigue..."
    # set password
    SetPassword

    # start services
    cd ~/core
    god start
    sleep 25
    ip=$(ifconfig eth0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
    echo "Browse to https://$ip:7777 and login with user 'intrigue' and the given or pregenerated password"
elif [ "$cmd" == "stop" ]; then
    echo "[+] Stopping intrigue..."
    cd ~/core
    god stop
elif [ "$cmd" == "setup" ]; then
    echo "[+] Initializing intrigue..."
    Setup
else
    echo "Unknown command."
    Help
fi