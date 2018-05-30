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

    def _create_browser_session
      begin

        # Start a new session
        session = Capybara::Session.new(:poltergeist)

      rescue Capybara::Poltergeist::TimeoutError => e
        _log_error "Fail Error: #{e}" if @task_result
      rescue Capybara::Poltergeist::StatusFailError => e
        _log_error "Fail Error: #{e}" if @task_result
      rescue Capybara::Poltergeist::JavascriptError => e
        _log_error "JS Error: #{e}" if @task_result
      end

    session
    end

    def capture_document(uri)

      session = _create_browser_session

      # browse to our target
      session.visit(uri)

      # Capture Title
      page_title = session.document.title
      _log_good "Title: #{page_title}" if @task_result

      session.driver.quit

    session.document
    end
    

    def capture_screenshot(uri)

      session = _create_browser_session

      # browse to our target
      session.visit(uri)

      # wait for the page to render
      sleep 3

      #
      # Capture a screenshot
      #
      tempfile = Tempfile.new(['phantomjs', '.png'])

      begin
        return_path = session.save_screenshot(tempfile.path)
        _log "Saved Screenshot to #{return_path}"
      rescue Capybara::Poltergeist::TimeoutError => e
        _log_error "Fail Error: #{e}" if @task_result
      rescue Capybara::Poltergeist::StatusFailError => e
        _log_error "Fail Error: #{e}" if @task_result
      rescue Capybara::Poltergeist::JavascriptError => e
        _log_error "JS Error: #{e}" if @task_result
      end

      # resize the image using minimagick
      image = MiniMagick::Image.open(return_path)
      image.resize "640x480"
      image.format "png"
      image.write tempfile.path

      # open and read the file's contents, and base64 encode them
      base64_image_contents = Base64.encode64(File.read(tempfile.path))

      # cleanup. note that this method is overridden, see initialize
      session.driver.quit

      # cleanup
      tempfile.close
      tempfile.unlink

    base64_image_contents
    end

    def gather_javascript_libraries(uri, libraries=[])


      # Test site: https://www.jetblue.com/plan-a-trip/#/
      # Examples: https://builtwith.angularjs.org/
      # Examples: https://www.madewithangular.com/

      session = _create_browser_session

      # browse to our target
      session.visit(uri)


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

        # run our script in a browser
        version = session.evaluate_script(check[:script])
        if version
          _log_good "Detected #{check[:library]} #{version}" if @task_result
          libraries << {"library" => "#{check[:library]}", "detected" => true, "version" => "#{version}" }
        end

      end

    libraries
    end


  end
end
end
