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

    def create_browser_session(uri="http://google.com")
      begin

        # Start a new session
        session = Capybara::Session.new(:poltergeist)

        # browse to our target
        session.visit(uri)

        # Capture Title
        page_title = session.document.title
        _log_good "Title: #{page_title}"


      rescue Capybara::Poltergeist::StatusFailError => e
        _log_error "Fail Error: #{e}"
      rescue Capybara::Poltergeist::JavascriptError => e
        _log_error "JS Error: #{e}"
      end

    session
    end


    def capture_screenshot(session)

      #
      # Capture a screenshot
      #
      tempfile = Tempfile.new(['phantomjs', '.png'])
      return_path = session.save_screenshot(tempfile.path)
      _log "Saved Screenshot to #{return_path}"

      # resize the image using minimagick
      image = MiniMagick::Image.open(return_path)
      image.resize "640x480"
      image.format "png"
      image.write tempfile.path

      # open and read the file's contents, and base64 encode them
      base64_image_contents = Base64.encode64(File.read(tempfile.path))

      # cleanup
      session.driver.quit
      tempfile.close
      tempfile.unlink

    base64_image_contents
    end

    def gather_javascript_libraries(session, hash)

      # Test site: https://www.jetblue.com/plan-a-trip/#/
      # Examples: https://builtwith.angularjs.org/
      # Examples: https://www.madewithangular.com/
      version = session.evaluate_script('angular.version.full')
      if version
        _log_good "Detected Angular #{version}"
        hash["angular"] = {
          "detected" => true,
          "version" => "#{version}"
        }
      else
        hash["angular"] = {
          "detected" => false
        }
      end


      # Test site: https://app.casefriend.com/
      # Examples: https://github.com/jashkenas/backbone/wiki/projects-and-companies-using-backbone
      version = session.evaluate_script('Backbone.VERSION')
      if version
        _log_good "Detected Backbone #{version}"
        hash["backbone"] = {
          "detected" => true,
          "version" => "#{version}"
        }
      else
        hash["backbone"] = {
          "detected" => false
        }
      end

      # Test site: https://d3js.org/
      # Examples: https://kartoweb.itc.nl/kobben/D3tests/index.html
      version = session.evaluate_script('d3.version')
      if version
        _log_good "Detected D3 #{version}"
        hash["d3"] = {
          "detected" => true,
          "version" => "#{version}"
        }
      else
        hash["d3"] = {
          "detected" => false
        }
      end

      # Test site: http://demos.dojotoolkit.org/demos/mobileCharting/demo.html
      # Examples: http://demos.dojotoolkit.org/demos/
      version = session.evaluate_script('dojo.version')
      if version
        _log_good "Detected Dojo #{version}"
        hash["dojo"] = {
          "detected" => true,
          "version" => "#{version}"
        }
      else
        hash["dojo"] = {
          "detected" => false
        }
      end

      # Test site: https://secure.ally.com/
      # Examples: http://builtwithember.io/
      version = session.evaluate_script('Ember.VERSION')
      if version
        _log_good "Detected Ember #{version}"
        hash["ember"] = {
          "detected" => true,
          "version" => "#{version}"
        }
      else
        hash["ember"] = {
          "detected" => false
        }
      end

      # Test site: http://www.eddiebauer.com/
      # Test site: https://www.underarmour.com
      version = session.evaluate_script('jQuery.fn.jquery')
      if version
        _log_good "Detected jQuery #{version}"
        hash["jquery"] = {
          "detected" => true,
          "version" => "#{version}"
        }
      else
        hash["jquery"] = {
          "detected" => false
        }
      end

      # Test site: http://www.eddiebauer.com/
      version = session.evaluate_script('jQuery.tools.version')
      if version
        _log_good "Detected jQuery Tools #{version}"
        hash["jquery_tools"] = {
          "detected" => true,
          "version" => "#{version}"
        }
      else
        hash["jquery_tools"] = {
          "detected" => false
        }
      end

      # Test site: http://www.eddiebauer.com/
      # Test site: https://www.underarmour.com
      version = session.evaluate_script('jQuery.ui.version')
      if version
        _log_good "Detected jQuery UI #{version}"
        hash["jquery_ui"] = {
          "detected" => true,
          "version" => "#{version}"
        }
      else
        hash["jquery_ui"] = {
          "detected" => false
        }
      end

      # Test site:
      # Examples: http://knockoutjs.com/examples/
      #version = session.evaluate_script('knockout.version')
      #if version
      #  _log_good "Detected Knockout #{version}"
      #  hash["knockout"] = {
      #    "detected" => true,
      #    "version" => "#{version}"
      #  }
      #else
      #  hash["knockout"] = {
      #    "detected" => false
      #  }
      #end

      # Test site: http://paperjs.org/examples/boolean-operations
      # Examples: http://paperjs.org/examples
      version = session.evaluate_script('paper.version')
      if version
        _log_good "Detected Paper.js #{version}"
        hash["paperjs"] = {
          "detected" => true,
          "version" => "#{version}"
        }
      else
        hash["paperjs"] = {
          "detected" => false
        }
      end

      # Test site:
      # Examples:
      #version = session.evaluate_script('Prototype.version')
      #_log_good "Using Prototype #{version}" if version
      #hash["prototype"] = "#{version}" if version

      # Test site: https://weather.com/
      # Examples: https://react.rocks/
      version = session.evaluate_script('React.version')
      if version
        _log_good "Detected React #{version}"
        hash["react"] = {
          "detected" => true,
          "version" => "#{version}"
        }
      else
        hash["react"] = {
          "detected" => false
        }
      end

      # Test site: https://www.homedepot.com
      version = session.evaluate_script('requirejs.version')
      if version
        _log_good "Detected RequireJS #{version}"
        hash["requirejs"] = {
          "detected" => true,
          "version" => "#{version}"
        }
      else
        hash["requirejs"] = {
          "detected" => false
        }
      end

      # Test site: https://app.casefriend.com/#sessions/login
      # Test site: https://store.dji.com/
      version = session.evaluate_script('_.VERSION')
      if version
        _log_good "Detected underscore #{version}"
        hash["underscore"] = {
          "detected" => true,
          "version" => "#{version}"
        }
      else
        hash["underscore"] = {
          "detected" => false
        }
      end

      # Test site: https://yuilibrary.com/yui/docs/event/basic-example.html
      # Examples: https://yuilibrary.com/yui/docs/examples/
      version = session.evaluate_script('YUI().version')
      if version
        _log_good "Detected YUI #{version}"
        hash["yui"] = {
          "detected" => true,
          "version" => "#{version}"
        }
      else
        hash["yui"] = {
          "detected" => false
        }
      end

    hash
    end


  end
end
end
