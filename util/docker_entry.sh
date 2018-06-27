#! /bin/bash
source ~/.bash_profile
service postgresql restart
service redis-server restart
/core/util/control.sh start
tail -f /core/log/sidekiq.log
