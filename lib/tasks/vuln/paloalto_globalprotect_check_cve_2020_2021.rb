module Intrigue
  module Task
  class  PaloAltoGlobalprotectCheckCve20202021 < BaseTask
  
    def self.metadata
      {
        :name => "vuln/paloalto_globalprotect_cve_2019_2021",
        :pretty_name => "Vuln Check - PaloAlto GlobalProtect Auth Bypass (CVE-2020-2021)",
        :authors => ["jcran"],
        :identifiers => [{ "cve" =>  "CVE-2020-2021" }],
        :description => "This task checks for the Palo Alto Globalprotect Authentication Bypass based on version. This is a potential check.",
        :references => [
          "https://security.paloaltonetworks.com/CVE-2020-2021"
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
      
      ###
      ### Get the base url, to ensure we're configured for the vuln (no 2fa / client certs enabled)
      ###

      response = http_request(:get, "#{_get_entity_name}/global-protect/login.esp")
      rbody = response.body 
      if !(rbody =~ /SAMLRequest/) # standard response 
        _log "Not vulnerable - no 2FA detected"
        return 
      end

      ###
      ### Then check version
      ###

      check_url = "#{_get_entity_name}/global-protect/portal/js/ie10-viewport-bug-workaround.js"
      response = http_request(:get, check_url)
  
      # grab header
      last_modified_header = false
      response.each_header{|h| last_modified_header = response[h] if h =~ /Last-Modified/i}
      unless last_modified_header
        _log "No Last-Modified Header! Failing"
        return
      end
  
      # Get the date to see it's vuln
      matches = last_modified_header.match(/(Jan 2020|Feb 2020|Mar 2020|Apr 2020|May 2020|15 Jun 2020|2019|2018|2017|2016)/i)
  
      # check that it matches our known vuln versions
      if matches && matches.captures && matches.captures.first
        date = matches.captures.first.strip
        _log "Checking... #{last_modified_header}, got date: #{date}"
        vulnerable = true
      else
        _log "No capture :["
      end
  
      # example: Last-Modified: Wed, 06 Jun 2018 20:52:55 GMT
      if vulnerable
        _log "Potentially Vulnerable! Please check configuration"
        _create_linked_issue("paloalto_globalprotect_cve_2019_2021", { proof: last_modified_header })
      else
        _log "Not Vulnerable! Header: #{last_modified_header}"
      end
  
    end
  
   
  end
  end
  end
  