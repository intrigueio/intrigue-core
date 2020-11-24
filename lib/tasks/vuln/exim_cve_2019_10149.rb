module Intrigue
  module Task
  class EximCve201910149 < BaseTask
  
    def self.metadata
      {
        :name => "vuln/exim_cve_2019_10149",
        :pretty_name => "Vuln Check - Exim RCE (CVE-2019-10149)",
        :authors => ["qualys", "jcran"],
        :identifiers => [{ "cve" => "CVE-2019-10149" }],
        :description => "Determines if the endpoint is vulnerable to CVE-2019-10149.",
        :references => [
          "https://www.qualys.com/2019/06/05/cve-2019-10149/return-wizard-rce-exim.txt",
          "https://www.openwall.com/lists/oss-security/2019/06/05/4",
          "https://www.tenable.com/blog/cve-2019-10149-critical-remote-command-execution-vulnerability-discovered-in-exim",
          "https://nvd.nist.gov/vuln/detail/CVE-2019-10149"
        ],
        :type => "vuln_check",
        :passive => false,
        :allowed_types => ["NetworkService"],
        :example_entities => [
          {"type" => "NetworkService", "details" => {"name" => "1.1.1.1:25/tcp"}}
        ],
        :allowed_options => [],
        :created_types => []
      }
    end
  
    ## Default method, subclasses must override this
    def run
      super
          
      # first, ensure we're fingerprinted
      require_enrichment
  
      network_service = _get_entity_name
      ip_address = network_service.split(":").first
      port = network_service.split(":").last.split("/").first
      
      fp = _get_entity_detail("fingerprint")
      
      unless fp   
        _log_error "Unable to continue, missing fingerprint"
        return
      end

      # check for exim
      if fp.select{|v| v['product'] =~ /Exim/i }.count > 0
        
        puts "EXIM!"
        puts "#{fp}!"

      end


    end
  
  end
  end
  end
  