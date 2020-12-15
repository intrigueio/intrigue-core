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
    echo "Syntax: ./intriguectl [start|stop]"
    echo "options:"
    echo "start  start intrigue services"
    echo "stop   stop intrigue services"
    echo
    echo "To set your basic auth password, export variable CORE_PASSWD"
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
          echo "Failed to set basic auth password. Check that your installation is in your home directory"
      fi
    fi
    
}

Setup()
{
    # check if we are a worker (we don't need to setup database if we are)
    if [ "${WORKER_CONFIG}" ]; then
      echo "We are a worker-only configuration!"
      return
    fi
    
    # else we set up the databases configuration
    echo "[+] Intrigue is starting for the first time! Setting up..."    

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
    sudo -u postgres createuser intrigue > /dev/null
    sudo -u postgres createdb intrigue_dev --owner intrigue > /dev/null

    # Adjust and spin up redis
    if [ ! -d /data/redis ]; then
      echo "[+] Configuring redis..."
      sudo service redis-server stop
      sudo mkdir -p /data/redis
      sudo chown redis:redis /data/redis
      sudo service redis-server start
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
    touch .setup_complete
    
    echo "[+] Setup complete! Starting services..."
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
    echo "Starting intrigue..."
    # set password
    SetPassword

    # check if setup has already run once
    FILE=~/core/.setup_complete
    if [ ! -f "$FILE" ]; then
       Setup
    fi

    # start services
    cd ~/core
    god start
    sleep 25
    ip=$(ifconfig eth0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
    echo "Browse to https://$ip:7777 and login with user 'intrigue' and the given or pregenerated password"

    # if we're in docker, we'll tail worker log
    if [ -f /.dockerenv ]; then
      tail -f /core/log/worker.log
    fi 
elif [ "$cmd" == "stop" ]; then
    cd ~/core
    god stop
else
    echo "Unknown command."
    Help
fi