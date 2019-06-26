eventmachine: bundle exec ruby ./util/eventmachine.rb
workers: bundle exec sidekiq -C ./config/sidekiq.yml -r ./core.rb
puma: bundle exec puma -C ./config/puma.rb -b tcp://127.0.0.1:7777
