require 'chrome_remote'
require 'base64'

module Intrigue
  class ChromeBrowser

    include Intrigue::Task::Generic

    # set host and port options if desired
    def initialize(options={})
      @requests = []
    
      # allow host & port to be set, and respect local config, then env, then default
      chrome_host = options[:host] || ENV["CHROME_HOST"]
      unless chrome_host && chrome_host.length > 0
        chrome_host = "127.0.0.1"
      end
      options[:host] = chrome_host

      chrome_port = options[:port] || ENV["CHROME_PORT"].to_i
      unless chrome_port && chrome_port > 0
        chrome_port = 9222 
      end
      options[:port] = chrome_port

      puts "Using Chrome with options: #{options}"

      # create the client
      until @chrome 
        begin 
          _connect_and_enable options
        rescue Socketry::TimeoutError => e
          _killit(chrome_port)
          _connect_and_enable options # simply retry
        rescue StandardError => e
          _killit(chrome_port)
          _connect_and_enable options # simply retry
        end
      end
    end

    def navigate_and_capture(url)
      
      # Setup handler to log network requests
      @chrome.on "Network.requestWillBeSent" do |params|

        begin 
          hostname = URI.parse(params["request"]["url"]).host
        rescue URI::InvalidURIError => e
          hostname = nil
        end

        @requests << { 
          "hostname" => hostname, 
          "url" => params["request"]["url"], 
          "method" => params["request"]["method"], 
          "headers" => params["request"]["headers"]
        } 
      end

      encoded_screenshot=nil
      until encoded_screenshot
        begin 
          encoded_screenshot = _navigate_and_screenshot(url)
          _tear_down
        rescue Socketry::TimeoutError => e
          _killit(chrome_port)
        end
      end

      { "requests" => @requests, "encoded_screenshot" => encoded_screenshot["data"] }
    end

    def _killit(port)
      puts "Unable to connect to client to the service running on #{port}, killing it!!!"
      _unsafe_system "pkill -f -9 remote-debugging-port=#{port}"
      sleep 20
    end

    def _connect_and_enable(options)
      @chrome = ChromeRemote.client(options)
      # Enable events
      @chrome.send_cmd "Network.enable"
      @chrome.send_cmd "Page.enable"
    end

    def _navigate_and_screenshot(url)
      # Navigate to the site and wait for the page to load
      @chrome.send_cmd "Page.navigate", url: url
      @chrome.wait_for "Page.loadEventFired"

      # Take page screenshot
    encoded_screenshot = @chrome.send_cmd "Page.captureScreenshot"
    end

    def _tear_down
      sleep 1
      # Tear down the service (it'll auto-restart via process manager...  
      # so first check that the port number has been set)
      if ENV["CHROME_PORT"]
        chrome_port = "#{ENV["CHROME_PORT"]}".to_i

        # relies on sequential worker numbers
        chrome_worker_number = chrome_port - 9221
        
        # kill the process
        puts "Success! Killing and restarting our chrome service (#{chrome_worker_number}) running on: #{chrome_port}"
        _unsafe_system "pkill -f -9 remote-debugging-port=#{chrome_port} && god restart intrigue-chrome-#{chrome_worker_number}"
        sleep 5
      end
    end

  end
end
