require 'chrome_remote'
require 'base64'
require 'timeout'

module Intrigue
  class ChromeBrowser

    include Intrigue::Task::Generic

    # set host and port options if desired
    def initialize(options={})

      @requests = []
      @responses = []
      @wsresponses = []
    
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
        # WARN: NoMethodError: undefined method `bytesize' for :eof:Symbol
        rescue NoMethodError => e 
          puts "ERROR.... nomethoderror exception: #{e} when attempting to screenshot"
          _killitwithfire(chrome_port)
        rescue Socketry::TimeoutError => e
          puts "ERROR.... timeout exception: #{e} when attempting to screenshot"
          _killitwithfire(chrome_port)
        rescue StandardError => e 
          puts "ERROR.... standard exception: #{e} when attempting to screenshot"
          _killitwithfire(chrome_port)
        end
      end
    end

    def navigate_and_capture(url, timeout=45)

      puts "Chrome navigating and capturing: #{url}"
      out = {}

      begin 
        
        Timeout::timeout(timeout) do
      
          # Setup handler to log requests
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

          # setup handler for responses 
          @chrome.on "Network.responseReceived" do |params|
            @responses << { 
              "url" => params["response"]["url"], 
              "headers" => params["response"]["headers"], 
              "security" => params["response"]["securityDetails"]
            } 
          end 

          # setup handler for websocket responses 
          @chrome.on "Network.WebSocketRequest" do |params|
            @wsresponses << params
          end 

          encoded_screenshot=nil

          max_retries = 3
          tries = 0
          until encoded_screenshot || (tries > max_retries)
            tries +=1
            chrome_port = "#{ENV["CHROME_PORT"]}".to_i || 9222
            begin 

              puts "Attempt: #{tries}"
              encoded_screenshot = _navigate_and_screenshot(url)
              sleep 10

              # Tear down the service (it'll auto-restart via process manager...  
              # so first check that the port number has been set)  
              _killitwithfire(chrome_port)

            # WARN: NoMethodError: undefined method `bytesize' for :eof:Symbol
            rescue NoMethodError => e 
              puts "ERROR.... nomethoderror exception: #{e} when attempting to screenshot"
              _killitwithfire(chrome_port)
            rescue Socketry::TimeoutError => e
              puts "ERROR.... timeout exception: #{e} when attempting to screenshot"
              _killitwithfire(chrome_port)
            rescue StandardError => e 
              puts "ERROR.... standard exception: #{e} when attempting to screenshot"
              _killitwithfire(chrome_port)
            end
          end

          # grab screenshot data - it's possible this was nil, so check 
          screenshot_data = encoded_screenshot["data"] if encoded_screenshot

          out = { 
            "requests" => @requests, 
            "responses" => @responses, 
            "wsresponses" => @wsresponses, 
            "encoded_screenshot" => screenshot_data
          }

        end
       
      rescue Timeout::Error => e 
        puts "carrying on"
        _killitwithfire(chrome_port)
        out = {}
      end

    out
    end

    def _killitwithfire(port)

      # relies on sequential worker numbers
      port = 9222 if port == 0 # just a failsafe 
      chrome_worker_number = port - 9221
          
      _unsafe_system "pkill -f -9 remote-debugging-port=#{port} && god restart intrigue-chrome-#{chrome_worker_number}"

      sleep 6
    end

    def _connect_and_enable(options)
      @chrome = ChromeRemote.client(options)
      # Enable events
      @chrome.send_cmd "Network.enable"
      @chrome.send_cmd "Page.enable"
    end

    def _navigate_and_screenshot(url)
      # Navigate to the site and wait for the page to load
      begin
        @chrome.send_cmd "Page.navigate", url: url
        @chrome.wait_for "Page.loadEventFired"

        # Take page screenshot
        encoded_screenshot = @chrome.send_cmd "Page.captureScreenshot"
      rescue NameError => e
        puts "NameError FIX UPSTREAM :["
        return nil
      end
      
    encoded_screenshot
    end

  end
end
