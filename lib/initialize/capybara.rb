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

Capybara.javascript_driver = :poltergeist
Capybara.run_server = false
Capybara.default_selector = :xpath
Capybara.threadsafe = true
