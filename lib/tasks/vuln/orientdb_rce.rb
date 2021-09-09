module Intrigue
    module Task
    class OrientdbRce < BaseTask
    
      def self.metadata
        {
          :name => "vuln/orientdb_rce",
          :pretty_name => "Vuln Check - OrientDB Remote Code Execution",
          :authors => ["shpendk"],
          :identifiers => [],
          :description => "This task does a version check for OrientDB remote code execution",
          :references => ["https://ssd-disclosure.com/ssd-advisory-orientdb-code-execution/"],
          :type => "vuln_check",
          :passive => false,
          :allowed_types => ["Uri"],
          :example_entities => [{"type" => "Uri", "details" => {"name" => "https://intrigue.io:2480"}}],
          :created_types => []
        }
      end
    
      ## Default method, subclasses must override this
      def run
        super
    
        require_enrichment
    
        # check our fingerprints for a version
        our_version = nil
        fp = _get_entity_detail("fingerprint")
        fp.each do |f|
          if f["vendor"] == "Orientdb" && f["product"] == "Orientdb" && f["version"] != ""
            our_version = f["version"]
            break
          end
        end
    
        if our_version
          _log "Got version: #{our_version}"
        else
          _log_error "Unable to get version, failing"
          return
        end
        
        _log "Checking version against known vulnerable versions"
    
        if compare_versions_by_operator(our_version, "2.2.2", ">=") && compare_versions_by_operator(our_version, "2.2.22", "<=")
          _log_good "Vulnerable!"
          _create_linked_issue("orientdb_rce", {
            proof: {
              detected_version: our_version
            }
          })
        else
          _log "Not vulnerable!"
        end
      end
    
    end
    end
    end
    