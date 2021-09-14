module Intrigue
  module Task
  class TomcatPersistentManagerCve20209484 < BaseTask
  
    def self.metadata
      {
        :name => "vuln/tomcat_persistent_manager_cve_2020_9484",
        :pretty_name => "Vuln Check - Tomcat PersistManager Deserialization RCE (CVE-2020-8494)",
        :identifiers => [
          { "cve" =>  "CVE-2020-9484" }
        ],
        :authors => ["jcran","redtimmysecurity"],
        :description => "Deserialization RCE in Tomcat that requires an attacker to control a file on disk.",
        :references => [
          "https://github.com/masahiro331/CVE-2020-9484",
          "https://www.redtimmy.com/java-hacking/apache-tomcat-rce-by-deserialization-cve-2020-9484-write-up-and-exploit/",
          "https://www.contrastsecurity.com/security-influencers/remote-code-execution-deserialization-vulnerability"
        ],
        :type => "vuln_check",
        :passive => false,
        :allowed_types => ["Uri"],
        :example_entities => [ {"type" => "Uri", "details" => {"name" => "https://intrigue.io"}} ],
        :allowed_options => [ 
          { :name => "attacker_controlled_path", :regex => "alpha_numeric", :default => "../../../../../usr/local/tomcat/groovy" }
        ],
        :created_types => []
      }
    end
  
    ## Default method, subclasses must override this
    def run
      super
  
      require_enrichment

      uri = "#{_get_entity_name}/index.jsp"
      attacker_controlled_path = _get_option("attacker_controlled_path")
      
      test_jsession_header = { "cookie" => "JSESSIONID=#{attacker_controlled_path}" } 

      response = http_get_body uri, nil, test_jsession_header

      if response =~ /org.apache.catalina.session.FileStore/
        # vulnerable
        _create_linked_issue("tomcat_persistent_manager_cve_2020_9484", {
          proof: {
            response_body: response
          }
        })
      else 
        # not vulnerable  
        _log "Not vulnerable or unable to detect a file on disk"
      end
  
    end
  
  end
  end
  end
  