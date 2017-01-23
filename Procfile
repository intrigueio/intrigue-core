task-worker: bundle exec sidekiq -C config/sidekiq-task-interactive.yml -r ./core.rb
as-task-worker: bundle exec sidekiq -C config/sidekiq-task-autoscheduled.yml -r ./core.rb
app-worker: bundle exec sidekiq -C config/sidekiq-app.yml -r ./core.rb
web: bundle exec  puma -C ./config/puma.rb
