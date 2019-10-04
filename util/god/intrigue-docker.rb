God.pid_file_directory = '/core/tmp/pids'

God.watch do |w|
  w.group = "intrigue"
  w.name = "intrigue-web"
  w.dir = "/core" 
  w.start = "bundle exec puma -C /core/config/puma.rb -b tcp://0.0.0.0:7777"
  w.pid_file = File.join("/core/tmp/pids/puma.pid")
  w.keepalive
end

God.watch do |w|
  w.group = "intrigue"
  w.name = "intrigue-worker"
  w.dir = "/core" 
  w.start = "bundle exec sidekiq -C /core/config/sidekiq.yml -r /core/core.rb"
  w.pid_file = File.join("/core/tmp/pids/worker.pid")
  w.keepalive
end

=begin
God.watch do |w|
  w.group = "intrigue"
  w.name = "intrigue-resolver"
  w.dir = "/core" 
  w.start = "bundle exec ruby /core/util/resolver.rb"
  w.pid_file = File.join("/core/tmp/pids/resolver.pid")
  w.keepalive
end
=end

God.watch do |w|
  w.group = "intrigue"
  w.name = "intrigue-chrome"
  w.dir = "/core" 
  w.start = "chromium-browser --headless --disable-gpu --disable-dev-shm-usage --ignore-certificate-errors --disable-popup-blocking --disable-translate --remote-debugging-port=9222 --no-sandbox"
  w.pid_file = File.join("/core/tmp/pids/chrome.pid")
  w.keepalive
end

