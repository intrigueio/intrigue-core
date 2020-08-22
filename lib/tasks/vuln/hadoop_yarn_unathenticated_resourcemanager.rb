###
### Task is in good shape, just needs some option parsing, and needs to deal with paths
###
module Intrigue
  module Task
  class  HadoopYarnCheck < BaseTask
  
    def self.metadata
      {
        :name => "vuln/hadoop_yarn_unauthenticated_check",
        :pretty_name => "Vuln Check - Hadoop YARN unauthenicated check",
        :authors => ["jcran"],
        :identifiers => [],
        :description => "CHecks for unauthenticated resource manager access.",
        :references => [
          "https://github.com/google/tsunami-security-scanner-plugins/blob/11f0eb11b31a8f08e03090dbed2e89884c7fa279/google/detectors/exposedui/hadoop/yarn/src/main/java/com/google/tsunami/plugins/detectors/exposedui/hadoop/yarn/YarnExposedManagerApiDetector.java#L142"
        ],
        :type => "vuln_check",
        :passive => false,
        :allowed_types => ["Uri"],
        :example_entities => [{"type" => "Uri", "details" => {"name" => "https://intrigue.io"}}],
        :allowed_options => [],
        :created_types => []
      }
    end
  
    ## Default method, subclasses must override this
    def run
      super
      
      require_enrichment

      uri = _get_entity_name

      # pull off last '/' if it exists 
      if uri[-1] == "/"
        uri = uri[0..-2]
      end

      # post to endpoint with nothing
      response = http_request(:post, "#{uri}/ws/v1/cluster/apps/new-application")

      _log "Got response: #{response.body_utf8}"
      if response.body_utf8 == /WebApplicationException/
        _log "Vulnerable? Got exception"
        _create_linked_issue "hadoop_yarn_resourcemanager_api_access", {"proof": response.body_utf8}
      elsif response.body_utf8 == /application-id/
        json = JSON.parse(response.body_utf8)
        _log "Vulnerable! Created app: #{json["applicationid"]}"
        _create_linked_issue "hadoop_yarn_resourcemanager_api_access", {"proof": response.body_utf8}
      else 
        _log "Unknown response: #{response.body_utf8}"
      end
  
    end
  
   
  end
  end
  end
  