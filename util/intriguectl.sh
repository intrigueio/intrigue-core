#! /bin/bash

# Set path to include rbenv
source $HOME/.bash_profile

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
    echo "To set your basic auth password, export variable INTRIGUE_PASS and (re)run setup"
    echo
}

Setup()
{
    # check if we are a worker (we don't need to setup database if we are)
    if [ "${WORKER_CONFIG}" ]; then
      echo "[+] We are a worker-only configuration!"
      return
    fi

    # force user/db creation, just in case
    sudo -u postgres createuser intrigue 2> /dev/null
    sudo -u postgres createdb intrigue_dev --owner intrigue 2> /dev/null

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

cmd=$1

if [ -z "$cmd" ];
then
    Help
    exit
fi

if [ "$cmd" == "start" ]; then
    echo "[+] Starting intrigue..."
    # start services
    cd ~/core
    god start > /dev/null
    sleep 25
    ip=$(ifconfig eth0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
    echo "Browse to https://$ip:7777 and login with user 'intrigue' and the given or pregenerated password"
elif [ "$cmd" == "stop" ]; then
    echo "[+] Stopping intrigue..."
    cd ~/core
    god stop > /dev/null
elif [ "$cmd" == "setup" ]; then
    echo "[+] Initializing intrigue..."
    Setup
else
    echo "Unknown command."
    Help
fi