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


module Capybara::Webkit
  class Driver
    def quit
      `kill #{@browser.instance_variable_get("@connection").instance_variable_get("@pid")}`
    end
  end
end

Capybara.javascript_driver = :poltergeist
Capybara.run_server = false
Capybara.default_selector = :xpath
Capybara.threadsafe = true
