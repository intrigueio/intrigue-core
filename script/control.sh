#!/bin/bash

# Puma: intrigue-puma.pid
# Sidekiq: intrigue-sidekiq.pid

function start_server {
  # Application server
  bundle exec puma -C config/puma.rb
  bundle exec sidekiq -C config/sidekiq.yml -r ./core.rb -d -L ./log/intrigue-sidekiq.log
}

function stop_server {

  for x in `ls ./tmp/pids/*.pid`; do
    echo "Killing $x: `cat $x`"
    kill -KILL `cat $x`
  done

  echo "Cleaning up... "
  rm -rf tmp/pids/*.pid

  #for x  in `pgrep -l -f puma| cut -d ' ' -f 1`;do kill -9 $x;done
  #for x  in `pgrep -l -f sidekiq| cut -d ' ' -f 1`;do kill -9 $x;done
}

function status_server {
  # Puma
  if [ -f ./tmp/pids/intrigue-puma.pid ]; then
    echo "Puma running"
  else
    echo "Puma not running"
  fi
  # Sidekiq
  if [ -f ./tmp/pids/intrigue-sidekiq.pid ]; then
    echo "Sidekiq running"
  else
    echo "Sidekiq not running"
  fi
}

# Carry out specific functions when asked to by the system
case "$1" in
  status)
    status_server
    ;;
  start)
    echo "Starting intrigue-core"
    start_server
    ;;
  stop)
    echo "Stopping intrigue-core"
    stop_server
    ;;
  restart)
    echo "Restarting intrigue-core"
    stop_server
    start_server
    ;;
  *)
    echo "Usage: /etc/init.d/blah {start|stop}"
    exit 1
    ;;
esac

exit 0
