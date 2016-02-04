web: bundle exec puma -C ./config/puma.rb
task-worker: bundle exec sidekiq -C config/intrigue-task.yml -r ./core.rb
scan-worker: bundle exec sidekiq -C config/sidekiq-scan.yml -r ./core.rb
