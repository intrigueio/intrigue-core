module Intrigue
  module Issue
  class ExposedCitrixAdcManagementInterface < BaseIssue
  
    def self.generate(instance_details={})
      {
        added: "2020-01-01",
        name: "exposed_citrix_adc_management_interface",
        pretty_name: "Exposed Citrix ADC Management Interface",
        severity: 2, 
        category: "network",
        status: "confirmed",
        description: "The Citrix ADC Management interface  was discovered. This should never be exposed to the data networks, and should be checked for vulnerabilties",
        remediation: "Prevent access to this panel by placing it behind a firewall or otherwise restricting access.",
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          {:type => "description", :uri => "https://blog.unauthorizedaccess.nl/2020/07/07/adventures-in-citrix-security-research.html"}
        ],
        # task: handled in ident
      }.merge!(instance_details)
    end
  
  end
  end
  end