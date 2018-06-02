# SETUP
require 'capybara'
require 'capybara/poltergeist'




Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, {
    :js_errors => false,
    :phantomjs_options => [
      '--debug=false',
      '--ignore-ssl-errors=true',
      '--ssl-protocol=any' ]
  })
end

module Capybara::Poltergeist
  class Client
    def self.process_killer(pid)
      proc do
        begin
          Process.kill('KILL', pid)
        rescue Errno::ESRCH, Errno::ECHILD
          # Zed's dead, baby
        rescue => ex
          puts "Error killing phantomjs, #{ex.message}"
          raise
        end
      end
    end
  end
end

Capybara.threadsafe = true
Capybara.javascript_driver = :poltergeist
Capybara.run_server = false
Capybara.default_selector = :xpath
