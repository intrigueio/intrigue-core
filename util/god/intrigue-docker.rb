BASEDIR="/core"
God.pid_file_directory = "#{BASEDIR}/tmp/pids"

God.watch do |w|
  w.group = "intrigue"
  w.name = "intrigue-web"
  w.dir = "#{BASEDIR}" 
  w.log = "#{BASEDIR}/log/web.log"
  w.start = "bundle exec puma -C #{BASEDIR}/config/puma.rb -b tcp://0.0.0.0:7777"
  w.pid_file = File.join("#{BASEDIR}/tmp/pids/puma.pid")
  w.keepalive
end

God.watch do |w|
  w.group = "intrigue"
  w.name = "intrigue-worker"
  w.dir = "#{BASEDIR}" 
  w.log = "#{BASEDIR}/log/worker.log"
  w.start = "bundle exec sidekiq -C #{BASEDIR}/config/sidekiq.yml -r #{BASEDIR}#{BASEDIR}.rb"
  w.pid_file = File.join("#{BASEDIR}/tmp/pids/worker.pid")
  w.keepalive
end

God.watch do |w|
  w.group = "intrigue"
  w.name = "intrigue-resolver"
  w.dir = "#{BASEDIR}" 
  w.log = "#{BASEDIR}/log/resolver.log"
  w.start = "bundle exec ruby #{BASEDIR}/util/resolver.rb"
  w.pid_file = File.join( "#{BASEDIR}/tmp/pids/resolver.pid")
  w.keepalive
end

God.watch do |w|
  w.group = "intrigue"
  w.name = "intrigue-chrome"
  w.dir = "#{BASEDIR}" 
  w.log = "#{BASEDIR}/log/chome.log"
  w.start = "chromium-browser --headless --disable-gpu --disable-dev-shm-usage --ignore-certificate-errors --disable-popup-blocking --disable-translate --remote-debugging-port=9222 --no-sandbox"
  w.pid_file = File.join("#{BASEDIR}/tmp/pids/chrome.pid")
  w.keepalive
end

God.watch do |w|
  w.group = "intrigue"
  w.name = "intrigue-tika"
  w.dir = "#{BASEDIR}" 
  w.log = "#{BASEDIR}/log/tika.log"
  w.start = "java -jar #{BASEDIR}/tmp/tika-server-1.22.jar"
  w.pid_file = File.join("#{BASEDIR}/tmp/pids/tika.pid")
  w.keepalive
end