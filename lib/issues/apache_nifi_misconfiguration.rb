module Intrigue
    module Issue
    class ApacheNifiMisconfiguration < BaseIssue
    
    def self.generate(instance_details={})
      {
        added: "2021-01-18",
        name: "apache_nifi_misconfiguration",
        pretty_name: "Apache NiFi Misconfiguration",
        severity: 1,
        status: "potential",
        category: "vulnerability",
        description: "This system has been misconfigured and allows unauthenticated access to the Apache NiFi interface. This allows attackers to perform remote code execution.",
        remediation: "Enable authentication for Apache NiFi.",
        affected_software: [ 
          { :vendor => "Apache", :product => "NiFi" },
        ],
        references: [
          { type: "description", uri: "https://labs.f-secure.com/tools/metasploit-modules-for-rce-in-apache-nifi-and-kong-api-gateway/" },
          { type: "exploit", uri: "https://github.com/rapid7/metasploit-framework/blob/master/modules/exploits/multi/http/apache_nifi_processor_rce.rb" }
        ], 
        task: "vuln/apache_nifi_misconfiguration"
      }.merge!(instance_details)
    end
    end
    end
    end
    