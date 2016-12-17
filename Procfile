web: bundle exec puma -C ./config/puma.rb
interactive-worker: bundle exec sidekiq -C config/sidekiq-task-interactive.yml -r ./core.rb
autoscheduled-worker: bundle exec sidekiq -C config/sidekiq-task-autoscheduled.yml -r ./core.rb
