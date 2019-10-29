module Intrigue
module Task
class UriScreenshot < BaseTask
  sidekiq_options :queue => "task_browser", :backtrace => true

  #include Intrigue::Task::Scanner
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
    rescue StandardError => e
      `pkill -9 chromium` # hacktastic
    end

    if browser_response 
      # capture a screenshot and save it as a detail
      _set_entity_detail("hidden_screenshot_contents",browser_response["encoded_screenshot"])
      _set_entity_detail("extended_screenshot_contents",browser_response["encoded_screenshot"])
      _set_entity_detail("extended_requests",browser_response["requests"])
    end

  end

end
end
end
