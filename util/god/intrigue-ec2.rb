God.pid_file_directory = '/home/ubuntu/core/tmp/pids'

God.watch do |w|
  w.group = "intrigue"
  w.name = "intrigue-web"
  w.dir = "/home/ubuntu/core" 
  w.start = "bundle exec puma -C /home/ubuntu/core/config/puma.rb -b tcp://0.0.0.0:7777"
  w.pid_file = File.join("/core/tmp/pids/puma.pid")
  w.keepalive
end

God.watch do |w|
  w.group = "intrigue"
  w.name = "intrigue-worker"
  w.dir = "/home/ubuntu/core" 
  w.start = "bundle exec sidekiq -C /home/ubuntu/core/config/sidekiq.yml -r /home/ubuntu/core/core.rb"
  w.pid_file = File.join("/core/tmp/pids/worker.pid")
  w.keepalive
end

God.watch do |w|
  w.group = "intrigue"
  w.name = "intrigue-resolver"
  w.dir = "/home/ubuntu/core" 
  w.start = "bundle exec ruby /home/ubuntu/core/util/resolver.rb"
  w.pid_file = File.join("/core/tmp/pids/resolver.pid")
  w.keepalive
end

God.watch do |w|
  w.group = "intrigue"
  w.name = "intrigue-chrome"
  w.dir = "/home/ubuntu/core" 
  w.start = "chromium-browser --headless --disable-gpu --disable-dev-shm-usage --ignore-certificate-errors --disable-popup-blocking --disable-translate --remote-debugging-port=9222 --no-sandbox"
  w.pid_file = File.join("/home/ubuntu/core/tmp/pids/chrome.pid")
  w.keepalive
end

