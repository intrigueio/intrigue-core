###
### Please note - these methods may be used inside task modules, or inside libraries within
### Intrigue. An attempt has been made to make them abstract enough to use anywhere inside the
### application, but they are primarily designed as helpers for tasks. This is why you'll see
### references to @task_result in these methods. We do need to check to make sure it's available before
### writing to it.
###

# This module exists for common web functionality - inside a web browser
module Intrigue
module Task
  module Browser

    def create_browser_session
      # Start a new session
      Capybara::Session.new(:headless_chrome)
    end

    def destroy_browser_session(session)
      sleep 10
      session.driver.quit
    end

    def safe_browser_action
      begin
        results = yield
      rescue Capybara::ElementNotFound => e
        _log_error "Element not found: #{e}" if @task_result
      rescue Net::ReadTimeout => e
        _log_error "Timed out, moving on" if @task_result
      rescue Selenium::WebDriver::Error::WebDriverError => e
        unless ("#{e}" =~ /is not defined/ || "#{e}" =~ /Cannot read property/)
          _log_error "Webdriver issue #{e}" if @task_result
        end
      rescue Selenium::WebDriver::Error::NoSuchWindowError => e
        _log_error "Lost our window #{e}" if @task_result
      rescue Selenium::WebDriver::Error::UnknownError => e
        # skip simple errors where we're testing JS libs
        unless ("#{e}" =~ /is not defined/ || "#{e}" =~ /Cannot read property/)
          _log_error "#{e}" if @task_result
        end
      rescue Selenium::WebDriver::Error::UnhandledAlertError => e
        _log_error "Unhandled alert #{e}" if @task_result
      rescue Selenium::WebDriver::Error::NoSuchElementError
        _log_error "No such element #{e}, moving on" if @task_result
      rescue Selenium::WebDriver::Error::StaleElementReferenceError
        _log_error "No such element ref #{e}, moving on" if @task_result
      end
    results
    end

    def capture_document(session, uri)
      # browse to our target
      safe_browser_action do
        session.visit(uri)
      end

      # Capture Title
      page_contents = session.document.text(:all)
      page_title = session.document.title
      # TODO ... DOM

    { :title => page_title, :contents => page_contents }
    end


    def capture_screenshot(session, uri)
      # browse to our target
      safe_browser_action do
        session.visit(uri)
      end

      # wait for the page to render
      #sleep 5

      #
      # Capture a screenshot
      #
      tempfile = Tempfile.new(['screenshot', '.png'])

      safe_browser_action do
        session.save_screenshot(tempfile.path)
        _log "Saved Screenshot to #{tempfile.path}"
      end

      # open and read the file's contents, and base64 encode them
      base64_image_contents = Base64.encode64(File.read(tempfile.path))

      # cleanup
      tempfile.close
      tempfile.unlink

    base64_image_contents
    end

    def gather_javascript_libraries(session, uri)

      # Test site: https://www.jetblue.com/plan-a-trip/#/
      # Examples: https://builtwith.angularjs.org/
      # Examples: https://www.madewithangular.com/

      safe_browser_action do
        session.visit(uri)
      end

      libraries = []

      checks = [
        { library: "Angular", script: 'angular.version.full' },
        # Backbone
        # Test site: https://app.casefriend.com/
        # Examples: https://github.com/jashkenas/backbone/wiki/projects-and-companies-using-backbone
        { library: "Backbone", script: 'Backbone.VERSION' },
        # D3
        # Test site: https://d3js.org/
        # Examples: https://kartoweb.itc.nl/kobben/D3tests/index.html
        { library: "D3", script: 'd3.version' },
        # Dojo
        # Test site: http://demos.dojotoolkit.org/demos/mobileCharting/demo.html
        # Examples: http://demos.dojotoolkit.org/demos/
        { library: "Dojo", script: 'dojo.version' },
        # Ember
        # Test site: https://secure.ally.com/
        # Examples: http://builtwithember.io/
        { library: "Ember", script: 'Ember.VERSION' },
        # Jquery
        # Test site: http://www.eddiebauer.com/
        # Test site: https://www.underarmour.com
        { library: "jQuery", script: 'jQuery.fn.jquery' },
        # Jquery tools
        # Test site: http://www.eddiebauer.com/
        { library: "jQuery Tools", script: 'jQuery.tools.version' },
        # Jquery UI
        # Test site: http://www.eddiebauer.com/
        # Test site: https://www.underarmour.com

        # Test site:
        # Examples: http://knockoutjs.com/examples/
        #version = session.evaluate_script('knockout.version')
        # { :product => "Knockout", check: 'knockout.version' }

        { library: "jQuery UI", script: 'jQuery.ui.version' },
        # Paper.js
        # Test site: http://paperjs.org/examples/boolean-operations
        # Examples: http://paperjs.org/examples

        # Prototype
        # Test site:
        # Examples:
        # version = session.evaluate_script('Prototype.version')
        # { product: "Prototype", check: 'Prototype.version' },

        { library: "Paper", script: 'paper.version' },

        # React
        # Test site: https://weather.com/
        # Examples: https://react.rocks/
        { library: "React", script: 'React.version' },

        # RequireJS
        # Test site: https://www.homedepot.com
        { library: "RequireJS", script: 'requirejs.version' },

        # Underscore
        # Test site: https://app.casefriend.com/#sessions/login
        # Test site: https://store.dji.com/
        { library: "Underscore", script: '_.VERSION' },

        # YUI
        # Test site: https://yuilibrary.com/yui/docs/event/basic-example.html
        # Examples: https://yuilibrary.com/yui/docs/examples/
        { library: "YUI", script: 'YUI().version' }
      ]

      checks.each do |check|

        hacky_javascript = "#{check[:script]};"

        # run our script in a browser
        version = safe_browser_action do
          session.evaluate_script(hacky_javascript)
        end

        if version
          _log_good "Detected #{check[:library]} #{version}" if @task_result
          libraries << {"library" => "#{check[:library]}", "version" => "#{version}" }
        end

      end

    libraries
    end


  end
end
end
