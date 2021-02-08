module Intrigue
    module Issue
    class ResolvesToLocalhost < BaseIssue
    
      def self.generate(instance_details={})
        {
          added: "2021-01-07",
          name: "resolves_to_localhost",
          pretty_name: "DNS record points to localhost",
          severity: 5,
          category: "misconfiguration",
          status: "confirmed",
          description: "A DNS record or Domain has been found to point to localhost. Under certain circumstances, this may lead to same-site scripting.",
          remediation: "Remove the DNS record.",
          affected_software: [],
          references: [
            { type: "description", uri: "https://www.securityfocus.com/archive/1/486606/30/0/threaded" }
          ]
        }.merge!(instance_details)
      end
    
    end
    end
    end
    
    
            