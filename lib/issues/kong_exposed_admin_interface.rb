module Intrigue
    module Issue
    class KongExposedAdminInterface < BaseIssue
    
      def self.generate(instance_details={})
        {
          added: "2021-01-15",
          name: "kong_exposed_admin_interface",
          pretty_name: "Kong Exposed Admin Interface",
          severity: 1,
          category: "misconfiguration",
          status: "potential",
          description: "This server is exposing the administrator interface for Kong API, which allows remote code execution if certain plugins are enabled.",
          remediation: "Disable internet exposure for the Kong API administrator interface.",
          affected_software: [ 
            { :vendor => "Kong", :product => "Kong" }
          ],
          references: [
            { type: "description", uri: "https://labs.f-secure.com/tools/metasploit-modules-for-rce-in-apache-nifi-and-kong-api-gateway/" },
            { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2020-11710" },
            { type: "Exploit", uri: "https://github.com/rapid7/metasploit-framework/blob/master/modules/exploits/multi/http/kong_gateway_admin_api_rce.rb" } 
          ], 
          check: "vuln/kong_exposed_admin_interface"
        }.merge!(instance_details)
      end
    
    end
    end
    end
    
    
            