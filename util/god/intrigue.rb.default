God.pid_file_directory = "/home/ubuntu/core/tmp/pids"
BASEDIR="/home/ubuntu/core"

God.watch do |w|
  w.group = "intrigue"
  w.name = "intrigue-web"
  w.dir = "#{BASEDIR}" 
  w.log = "#{BASEDIR}/log/web.log"
  w.start = "bundle exec puma -C #{BASEDIR}/config/puma.rb"
  w.keepalive
end

God.watch do |w|
  w.group = "intrigue"
  w.name = "intrigue-worker"
  w.env = { "CHROME_PORT" => "9222" }
  w.dir = "#{BASEDIR}" 
  w.log = "#{BASEDIR}/log/worker.log"
  w.start = "bundle exec sidekiq -C #{BASEDIR}/config/sidekiq.yml -r #{BASEDIR}/core.rb"
  w.keepalive
end

God.watch do |w|
  w.group = "intrigue"
  w.name = "intrigue-resolver"
  w.dir = "#{BASEDIR}" 
  w.log = "#{BASEDIR}/log/resolver.log"
  w.start = "bundle exec ruby #{BASEDIR}/util/resolver.rb"
  w.keepalive
end

God.watch do |w|
  w.group = "intrigue"
  w.name = "intrigue-chrome"
  w.dir = "#{BASEDIR}" 
  w.log = "#{BASEDIR}/log/chome.log"
  w.start = "chromium-browser --remote-debugging-port=9222 --headless --disable-gpu --disable-dev-shm-usage --ignore-certificate-errors --disable-popup-blocking --disable-translate --no-sandbox --ignore-certificate-errors-spki-list --ignore-ssl-errors"
  w.keepalive
end

God.watch do |w|
  w.group = "intrigue"
  w.name = "intrigue-tika"
  w.dir = "#{BASEDIR}" 
  w.log = "#{BASEDIR}/log/tika.log"
  w.start = "java -jar #{BASEDIR}/tmp/tika-server.jar"
  w.keepalive
end