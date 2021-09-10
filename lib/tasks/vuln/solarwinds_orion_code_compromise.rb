module Intrigue
    module Task
    class SolarWindsOrionCodeCompromise < BaseTask
  
      def self.metadata
        {
          :name => "vuln/solarwinds_orion_code_compromise",
          :pretty_name => "Vuln Check - SolarWinds Orion Code Compromise",
          :authors => ["shpendk"],
          :identifiers => [],
          :description => "This task checks the SolarWinds Orion Products for a version which was compromised.",
          :references => [
            "https://cyber.dhs.gov/ed/21-01/"
          ],
          :type => "vuln_check",
          :passive => false,
          :allowed_types => ["Uri"],
          :example_entities => [
            {"type" => "Uri", "details" => {"name" => "https://intrigue.io"}}
          ],
          :allowed_options => [],
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
          if f["vendor"] == "SolarWinds" && f["version"] != "" && f["version"] != nil
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
        
        # affected versions are 2019.4 through 2020.2.1 HF1
        if compare_versions_by_operator(our_version, "2019.4", ">=") && compare_versions_by_operator(our_version, "2020.2.1 HF1", "<=")
          _log_good "Vulnerable!"
          _create_linked_issue("solarwinds_orion_code_compromise", {
            proof: {
              detected_version: our_version
            }
          })
          return
        else
          _log "Version does not appear to be vulnerable"
        end
  
      end
  
    end
    end
    end
  