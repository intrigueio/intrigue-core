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
      @chrome = ChromeRemote.client(options)

      # Enable events
      @chrome.send_cmd "Network.enable"
      @chrome.send_cmd "Page.enable"
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

      # Navigate to github.com and wait for the page to load
      @chrome.send_cmd "Page.navigate", url: url
      @chrome.wait_for "Page.loadEventFired"

      # Take page screenshot
      encoded_screenshot = @chrome.send_cmd "Page.captureScreenshot"

      # give it time to screenshot 
      sleep 1

      # Tear down the service (it'll auto-restart via process manager...  
      # so first check that the port number has been set)
      if ENV["CHROME_PORT"]
        chrome_port = "#{ENV["CHROME_PORT"]}".to_i

        # relies on sequential worker numbers
        chrome_worker_number = chrome_port - 9221
        
        # kill the process
        _unsafe_system "pkill -f -9 remote-debugging-port=#{chrome_port} && god restart intrigue-chrome-#{chrome_worker_number}"
        
        # give it time to restart via process monitoring
        sleep 3
      end

      { "requests" => @requests, "encoded_screenshot" => encoded_screenshot["data"] }
    end

  end
end
