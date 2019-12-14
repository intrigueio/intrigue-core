require 'chrome_remote'
require 'base64'

module Intrigue
  class ChromeBrowser

    # set host and port options if desired
    def initialize(options={})
      @requests = []
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

      { "requests" => @requests, "encoded_screenshot" => encoded_screenshot["data"] }
    end

  end
end
