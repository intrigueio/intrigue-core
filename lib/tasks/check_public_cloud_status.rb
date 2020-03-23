module Intrigue
  module Task
  class CheckPublicCloudStatus < BaseTask
  
    def self.metadata
      {
        :name => "check_public_cloud_status",
        :pretty_name => "Check Cloud Status",
        :authors => ["jcran"],
        :description => "This task checks whether an entity is known to be hosteed in the public cloud.",
        :references => [],
        :type => "discovery",
        :passive => true,
        :allowed_types => ["DnsRecord", "IpAddress", "Uri"],
        :example_entities => [
          {"type" => "IpAddress", "details" => {"name" => "8.8.8.8"}}
        ],
        :allowed_options => [
        ],
        :created_types => ["IpAddress"]
      }
    end
  
    ## Default method, subclasses must override this
    def run
      super
  
      # Now that we have our core details, check cloud statusi
      cloud_providers = determine_cloud_status(@entity)
      _log "Got: #{cloud_providers}"

      _set_entity_detail "cloud_providers", cloud_providers.uniq.sort
      _set_entity_detail "cloud_hosted", !cloud_providers.empty?
        
    end
  
  end
  end
  end
  