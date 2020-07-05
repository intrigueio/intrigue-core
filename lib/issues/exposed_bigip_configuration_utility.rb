module Intrigue
  module Issue
  class ExposedBigipConfigurationUtility < BaseIssue
  
    def self.generate(instance_details={})
      {
        name: "exposed_bigip_configuration_utility",
        pretty_name: "Exposed BIG-IP Configuration Utility",
        severity: 3, 
        category: "network",
        status: "confirmed",
        description: "The F5 BigIP configutation utility was discovered. This should never be exposed to the data networks, and should be checked for CVE-2020-5902",
        remediation: "Prevent access to this panel by placing it behind a firewall or otherwise restricting access.",
        #affected_software: [
        #  { :vendor => "F5", :product => "Big-IP Configuration Utility" },
        #],
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          {:type => "threat_intel", :uri => "https://twitter.com/n0x08/status/1278812795031523328"}
        ],
        # task: handled in ident
      }.merge!(instance_details)
    end
  
  end
  end
  end