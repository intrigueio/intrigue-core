module Intrigue
    module Task
    class LoginizerCVE202027615 < BaseTask
    
      def self.metadata
        {
          :name => "vuln/wordpress_loginizer_cve_2020_27615",
          :pretty_name => "Vuln Check - Wordpress Loginizer Plugin SQL Injection - (CVE-2020-27615)",
          :authors => ["shpendk"],
          :identifiers => [{ "cve" =>  "CVE-2020-27615" }],
          :description => "This task does a version check for Loginizer SQL injection vulnerability (CVE-2020-27615)",
          :references => ["https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-27615"],
          :type => "vuln_check",
          :passive => false,
          :allowed_types => ["Uri"],
          :example_entities => [{"type" => "Uri", "details" => {"name" => "https://intrigue.io"}}],
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
          if f["vendor"] == "Wordpress" && f["product"] == "Loginizer"
            our_version = f["version"]
            break
          end
        end
    
        if our_version
          _log "Got version: #{our_version}"
        else
          _log_error "Unable to get version, failing."
          return
        end
    
        # check the version to see if its vulnerable.
        # versions smaller than 1.6.4 are vulnerable as per https://wpdeeply.com/loginizer-before-1-6-4-sqli-injection/
        _log "Checking version against known vulnerable versions"
    
        if ::Versionomy.parse(our_version) < ::Versionomy.parse("1.6.4")
          _log_good "Vulnerable!"
          _create_linked_issue("wordpress_loginizer_cve_2020_27615", {
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
    