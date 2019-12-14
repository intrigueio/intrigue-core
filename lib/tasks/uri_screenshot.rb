module Intrigue
module Task
class UriScreenshot < BaseTask

  include Intrigue::Task::Browser

  def self.metadata
    {
      :name => "uri_screenshot",
      :pretty_name => "URI Screenshot",
      :authors => ["jcran"],
      :description => "This task screenshots a Uri.",
      :references => [],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [
        {"type" => "Uri", "details" => {"name" => "http://www.intrigue.io"}}
      ],
      :allowed_options => [],
      :created_types =>  [],
      :queue => "task_browser"
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    uri = _get_entity_name
      
    begin 
      _log "Browser Navigating to #{uri}"
      c = Intrigue::ChromeBrowser.new
      browser_response = c.navigate_and_capture(uri)  
    rescue Errno::ECONNREFUSED => e 
      _log_error "Unable to connect to chrome browser. Is it running on :9222?"
    #rescue StandardError => e
    #  _log_error "Oops! Got error attempting to screenshot: #{e}"
    #  _log_error "Attempting to restart chromium."
    #  `pkill -9 chromium` # hacktastic
    end

    if browser_response 

      # look for mixed content
      if uri =~ /^https/
        _log "Since we're here (and https), checking for mixed content..."
        _check_requests_for_mixed_content(uri, browser_response["requests"])
      end

      # split out request hosts, and then verify them
      if browser_response["requests"]
        request_hosts = browser_response["requests"].map{|x| x["hostname"] }.compact.uniq.sort
        _log "Since we're here (and https), checking for mixed content..."
        _check_request_hosts_for_suspicious_request(uri, request_hosts)
        _check_request_hosts_for_uniquely_hosted_resources(uri,request_hosts)
      else
        request_hosts = []
      end

      # save screenshot and request details 
      #_set_entity_detail("hidden_screenshot_contents",browser_response["encoded_screenshot"])
      _set_entity_detail("extended_screenshot_contents",browser_response["encoded_screenshot"])
      _set_entity_detail("request_hosts",request_hosts)
      _set_entity_detail("extended_requests",browser_response["requests"])

    end

  end

end
end
end
