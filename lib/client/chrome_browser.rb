require 'chrome_remote'
require 'base64'

module Intrigue
  class ChromeBrowser

    def initialize
      @requests = []
      @chrome = ChromeRemote.client

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
      #File.write "screenshot.png", Base64.decode64()

      { "requests" => @requests, "encoded_screenshot" => encoded_screenshot["data"] }
    end

  end
end
