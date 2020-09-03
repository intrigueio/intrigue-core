module Intrigue
  module Task
  class WordpressFileManagerCommandInjectionRce < BaseTask
  
    def self.metadata
      {
        :name => "vuln/wordpress_file_manager_command_injection_rce",
        :pretty_name => "Vuln Check - Wordpress File Manager Command Injection RCE",
        :identifiers => [{ "cve" =>  "CVE-2020-xxxx" }],
        :authors => ["shpendk", "jcran", "w4fz5uck5"],
        :description => "RCE in the Wordpress File Manager Plugin",
        :references => [
          "https://blog.nintechnet.com/critical-0day-vulnerability-fixed-in-wordpress-easy-wp-smtp-plugin/"
        ],
        :type => "vuln_check",
        :passive => false,
        :allowed_types => ["Uri"],
        :example_entities => [ {"type" => "Uri", "details" => {"name" => "https://intrigue.io"}} ],
        :allowed_options => [  ],
        :created_types => []
      }
    end
  
    ## Default method, subclasses must override this
    def run
      super
  
      require_enrichment
  
      uri = _get_entity_name
  
      # request 1 
      #endpoint = "#{uri}/path/to_vuln"
      #headers = {}
      #payload = ''
      #http_request :post, endpoint. nil, headers, payload

      # request 2 
      #endpoint = "#{uri}/path/to_vuln"
      #headers = {}
      #http_request :get, endpoint. nil, headers

  
    end
  
  end
  end
  end
  