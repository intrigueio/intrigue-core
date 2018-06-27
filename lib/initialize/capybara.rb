require 'capybara'
require "selenium/webdriver"

Capybara.register_driver :headless_chrome do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
     chromeOptions: {
       args: %w[ headless disable-gpu window-size=640,480 proxy-server='direct://' proxy-bypass-list=* timeout=20000 ]
     }
   )
 Capybara::Selenium::Driver.new(app, browser: :chrome, desired_capabilities: capabilities)
end

Capybara.default_max_wait_time = 20
Capybara.default_selector = :xpath
Capybara.javascript_driver = :selenium_chrome_headless
Capybara.run_server = false
Capybara.threadsafe = true
