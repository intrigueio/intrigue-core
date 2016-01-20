#!/bin/bash

# Puma: intrigue-puma.pid
# Sidekiq: intrigue-sidekiq.pid

function start_server {
  # Application server
  bundle exec puma -C config/puma.rb
  bundle exec sidekiq -C config/sidekiq-scan.yml -r ./core.rb -d -L ./log/sidekiq-scan.log
  bundle exec sidekiq -C config/sidekiq-task.yml -r ./core.rb -d -L ./log/sidekiq-task.log
}

function stop_server {

  for x in `ls ./tmp/pids/*.pid`; do
    echo "Killing $x: `cat $x`"
    kill -KILL `cat $x`
  done

  echo "Cleaning up... "
  rm -rf tmp/pids/*.pid
}

function kill_all {
  for x  in `pgrep -l -f puma| cut -d ' ' -f 1`;do kill -9 $x;done
  for x  in `pgrep -l -f sidekiq| cut -d ' ' -f 1`;do kill -9 $x;done
}

function status_server {
  # Puma
  if [ -f ./tmp/pids/intrigue-puma.pid ]; then
    echo "Puma running"
  else
    echo "Puma not running"
  fi

  # Sidekiq -scan
  if [ -f ./tmp/pids/intrigue-sidekiq-scan.pid ]; then
    echo "Sidekiq scan process running"
  else
    echo "Sidekiq scan process not running"
  fi

  # Sidekiq -task
  if [ -f ./tmp/pids/intrigue-sidekiq-task.pid ]; then
    echo "Sidekiq task process running"
  else
    echo "Sidekiq task process not running"
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
  killall)
    echo "Killing all ruby and sidekiq processes!"
    kill_all
    ;;
  *)
    echo "Usage: control.sh {start|stop|restart|killall}"
    exit 1
    ;;
esac

exit 0
