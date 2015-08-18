#!/bin/bash

# restart thin
echo "Killing all instances of puma and sidekiq"
for x  in `pgrep -l -f puma| cut -d ' ' -f 1`;do kill -9 $x;done
for x  in `pgrep -l -f sidekiq| cut -d ' ' -f 1`;do kill -9 $x;done

#application serveri
echo "Starting app server"
#bundle exec puma -e production -d -b unix:///tmp/core_puma.sock
bundle exec puma -C config/puma.rb
bundle exec sidekiq -C config/sidekiq.yml -r ./core.rb -d -L log/intrigue-sidekiq.log
