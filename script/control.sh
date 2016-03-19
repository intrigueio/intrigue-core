#!/bin/bash

# Puma: intrigue-puma.pid
# Sidekiq: intrigue-sidekiq.pid

function setup_server {
  bundle exec rake migrate
}

function start_server {
  echo "Starting scan processing..."
  bundle exec sidekiq -C ./config/sidekiq-scan.yml -r ./core.rb -d -L ./log/scan.log
  echo "Starting task processing..."
  bundle exec sidekiq -C ./config/sidekiq-task.yml -r ./core.rb -d -L ./log/task.log
  echo "Starting puma..."
  bundle exec puma -b "tcp://0.0.0.0:7778" # listen on a public port
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
    echo "Starting intrigue-core processes (waiting 10 seconds...)"
    sleep 10
    setup_server
    start_server
    ;;
  stop)
    echo "Stopping intrigue-core processes"
    stop_server
    ;;
  restart)
    echo "Restarting intrigue-core"
    stop_server
    start_server
    ;;
  killall)
    echo "ALERT! Killing all ruby and sidekiq processes! This command is system-wide, so use with caution!"
    kill_all
    ;;
  *)
    echo "Usage: control.sh {start|stop|restart|killall}"
    exit 1
    ;;
esac

exit 0
