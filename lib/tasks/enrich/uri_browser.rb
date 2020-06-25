module Intrigue
module Task
module Enrich
class UriBrowser < BaseTask

  include Intrigue::Task::Browser

  def self.metadata
    {
      :name => "enrich/uri_browser",
      :pretty_name => "Enrich URI (with browser)",
      :authors => ["jcran"],
      :description => "This task screenshots a Uri, looks for api requests and a few common exposures that can be detected with a browser.",
      :references => [],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [
        {"type" => "Uri", "details" => {"name" => "http://www.intrigue.io"}}
      ],
      :allowed_options => [
        {:name => "create_issues", :regex => "boolean", :default => true }, 
        {:name => "create_endpoints", :regex => "boolean", :default => true },
        {:name => "create_wsendpoints", :regex => "boolean", :default => true },
      ],
      :created_types =>  [],
      :queue => "task_browser"
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    uri = _get_entity_name

    ###
    ### Browser-based data grab
    ### 
    browser_data_hash = capture_screenshot_and_requests(uri)
    # split out request hosts, and then verify them
    if !browser_data_hash.empty? && _get_option("create_endpoints")

      # look for mixed content
      if uri =~ /^https/
        _log "Since we're here (and https), checking for mixed content..."
        _check_requests_for_mixed_content(uri, browser_data_hash["extended_browser_requests"])
      end

      _log "Checking for other oddities..."
      request_hosts = browser_data_hash["request_hosts"]
      _check_request_hosts_for_suspicious_request(uri, request_hosts)
      _check_request_hosts_for_exernally_hosted_resources(uri,request_hosts)
    end

    ###
    ### Capture api endpoints (going forward this should be triggered by an event)
    ###
    if _get_option("create_endpoints")
      _log "Creating broswer endpoints"
      if browser_responses = browser_data_hash["extended_browser_responses"]
        _log "Creating #{browser_responses.count} endpoints"
        browser_responses.each do |r|
          next unless "#{r["uri"]}" =~ /^http/i
          _create_entity("ApiEndpoint", {"name" => r["url"] })
        end
      else 
        _log_error "Unable to create entities, missing 'extended_responses' detail"
      end
    else
      _log "Skipping normal browser responses"
    end

    if _get_option("create_wsendpoints")
      if browser_responses = browser_data_hash["extended_browser_wsresponses"]
        browser_responses.each do |r|
          next unless "#{r["uri"]}" =~ /^http/i
          _create_entity("ApiEndpoint", {"name" => r["url"] })
        end
      else 
        _log_error "Unable to create entities, missing 'extended_responses' detail"
      end
    else 
      _log "Skipping webservice browser responses"
    end

    # now merge them together and set as the new details
    _set_entity_details(_get_entity_details.merge(browser_data_hash))

  end

end
end
end
end