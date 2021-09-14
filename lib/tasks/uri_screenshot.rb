module Intrigue
  module Task
  module Enrich
  class UriScreenshot < BaseTask

    include Intrigue::Task::Browser

    def self.metadata
      {
        :name => "uri_screenshot",
        :pretty_name => "URI Screenshot Web Page",
        :authors => ["jcran"],
        :description => "This task screenshots a Uri, looks for api requests and a few common exposures that can be detected with a browser.",
        :references => [],
        :type => "discovery",
        :passive => false,
        :allowed_types => ["ApiEndpoint","Uri"],
        :example_entities => [
          {"type" => "Uri", "details" => {"name" => "http://www.intrigue.io"}}
        ],
        :allowed_options => [
          {:name => "create_issues", :regex => "boolean", :default => true },
          {:name => "create_endpoints", :regex => "boolean", :default => false },
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
      ### If deny_list or hidden, just return (saves resources)
      ###
      if @entity.hidden || @entity.deny_list
        _log "this is a hidden / denied endpoint, we're returning"
        return
      end

      ###
      ### Browser-based data grab
      ###
      browser_data_hash = capture_screenshot_and_requests(uri)
      if browser_data_hash.empty?
        _log "empty hash, returning w/o setting details"
        return
      end

      # now merge them together and set as the new details
      _get_and_set_entity_details browser_data_hash

    end

  end
  end
  end
  end