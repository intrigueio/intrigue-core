require 'chrome_remote'
require 'base64'

module Intrigue
  class ChromeBrowser

    # set host and port options if desired
    def initialize(options={})
      @requests = []
    
      # allow port to be set, and respect local config, then env, then default
      port_number = options[:port] || "#{ENV["CHROME_PORT"]}".to_i || 9222
      options[:port] = port_number

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
        processes = unsafe_system("sudo lsof -t -i:#{chrome_port}")
        processes.split("\n").each do |p|
          unsafe_system "kill -9 #{p.strip}"
        end

        # give it time to restart
        sleep 3
      end

      { "requests" => @requests, "encoded_screenshot" => encoded_screenshot["data"] }
    end

  end
end
