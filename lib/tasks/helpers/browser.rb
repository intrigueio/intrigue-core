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

    def capture_screenshot_and_requests(uri)
      return {} unless Intrigue::Core::System::Config.config["browser_enabled"]

      # First, make sure we can actually connect to it in reasonable time
      response = http_request(:get, uri, nil, {}, nil, true, 10)
      return {} unless response

      begin
        _log "Browser Navigating to #{uri}"
        c = Intrigue::ChromeBrowser.new
        browser_response = c.navigate_and_capture(uri)
      rescue Errno::ECONNREFUSED => e
        _log_error "Unable to connect to chrome browser. Is it running as a service?"
      end

      if browser_response && browser_response["requests"]

        to_return = {
          "extended_screenshot_contents" => browser_response["encoded_screenshot"],
          "screenshot_exists" => (browser_response["encoded_screenshot"] ? true : false),
          "request_hosts" => browser_response["requests"].map{|x| x["hostname"] }.compact.uniq.sort,
          "extended_browser_request_urls" => browser_response["requests"].map{|x| x["url"] }.compact.uniq.sort,
          "extended_browser_requests" => browser_response["requests"],
          "extended_browser_responses" => browser_response["responses"],
          "extended_browser_wsresponses" => browser_response["wsresponses"],
          "extended_browser_page_capture" => browser_response["page_capture"]
        }

      else
        to_return = {}
      end

    to_return
    end

    # TODO
    # TODO ... convert this to new way of controlling browser
    # TODO
    def gather_javascript_libraries(session, uri)
      return [] unless Intrigue::Core::System::Config.config["browser_enabled"]

      # Test site: https://www.jetblue.com/plan-a-trip/#/
      # Examples: https://builtwith.angularjs.org/
      # Examples: https://www.madewithangular.com/

      safe_browser_action do
        session.navigate.to(uri)
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

        # Honeybadger
        { library: "Honeybadger", script: 'Honeybadger.getVersion()' },

        # Intercom
        # Examples: https://bugcrowd.com
        { library: "Intercom", script: 'Intercom("version")' },

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
        { library: "jQuery UI", script: 'jQuery.ui.version' },

        # Test site:
        # Examples: http://knockoutjs.com/examples/
        #version = session.evaluate_script('knockout.version')
        # { :product => "Knockout", check: 'knockout.version' }

        # Modernizr
        { library: "Modernizr", script: 'Modernizr._version' },

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

        hacky_javascript = "return #{check[:script]};"

        # run our script in a browser
        version = safe_browser_action do
          session.execute_script(hacky_javascript)
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
