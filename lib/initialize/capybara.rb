require 'capybara'
require "selenium/webdriver"

Capybara.register_driver :headless_chrome do |app|

  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')

  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    acceptInsecureCerts: true,
    chromeOptions: {
      'args' => [
        '--headless', '--disable-web-security', '--incognito',
        '--disable-dev-shm-usage', '--no-sandbox', '--disable-gpu',
        '--window-size=640,480' ]
    })

  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    desired_capabilities: capabilities,
    options: options
  )
end

Capybara.default_max_wait_time = 20
Capybara.default_selector = :xpath
Capybara.javascript_driver = :headless_chrome
Capybara.run_server = false
Capybara.threadsafe = true
