module Intrigue
  module Task
  class SearchC99Subdomainfinder < BaseTask
  
    def self.metadata
      {
        :name => "search_c99_subdomainfinder",
        :pretty_name => "Search c99 Subdomainfinder",
        :authors => ["jcran"],
        :description => "This task queries the c99 API for subdomains.",
        :references => [],
        :type => "discovery",
        :passive => true,
        :allowed_types => ["Domain"],
        :example_entities => [
          {"type" => "Domain", "details" => {"name" => "intrigue.io"}}
        ],
        :allowed_options => [],
        :created_types => ["DnsRecord"]
      }
    end
  
    ## Default method, subclasses must override this
    def run
      super
  
      entity_name = _get_entity_name
      api_key = _get_task_config("c99_subdomainfinder_api_key")
      #limit = _get_option("limit")
  
      begin 
        url = "https://api.c99.nl/subdomainfinder?key=#{api_key}&domain=#{entity_name}&json"
        response = http_get_body(url)
        result = JSON.parse(response)
      rescue JSON::ParserError => e
        require 'pry'
        binding.pry
        _log_error "Unable to parse, not JSON!"
        return  
      end
      
      ### parse it up 
      if result["success"]

        result["subdomains"].each do |s|
          _log "Working on #{s}"
          _create_entity "DnsRecord", "name" => s["subdomain"]
        end

      else
        _log_error "No success message"
      end
  
    end #end run
  
  end
  end
  end
  