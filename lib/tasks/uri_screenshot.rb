module Intrigue
  module Task
  module Enrich
  class UriScreenshot < BaseTask
  
    include Intrigue::Task::Browser
  
    def self.metadata
      {
        :name => "uri_screenshot",
        :pretty_name => "Uri Screenshot",
        :authors => ["jcran"],
        :description => "This task screenshots a Ur",
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