module Intrigue
  module Issue
  class F5BigIpConfigurationUtilityCve20205902 < BaseIssue
  
    def self.generate(instance_details={})
      {
        added: "2020-07-03",
        name: "f5_bigip_configuration_utility_cve_2020_5902",
        pretty_name: "F5 BIG-IP Config Utility RCE (CVE-2020-5902)",
        identifiers: [
          { type: "CVE", name: "CVE-2020-5902" }
        ],
        integrated: "2020-07-05 21:33:03 UTC",
        severity: 1, 
        category: "vulnerability",
        status: "confirmed",
        description: "This Big-IP Configuration Utility was discovered and found vulnerable to CVE-2020-5902",
        remediation: "Update the device, and if possible, remove access from this network.",
        affected_software: [
          { :vendor => "F5", :product => "BIG-IP Configuration Utility" }
        ],
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          {:type => "description", :uri => "https://support.f5.com/csp/article/K52145254" },
          {:type => "description", :uri => "https://threader.app/thread/1279894238793216001" },
          {:type => "threat_intel", :uri => "https://twitter.com/n0x08/status/1278812795031523328"}, 
          {:type => "exploit", :uri => "https://github.com/Critical-Start/Team-Ares/blob/master/CVE-2020-5902/CVE-2020-5902.sh"}
        ],
        check: "vuln/f5_bigip_configuration_utility_cve_2020_5902"
      }.merge!(instance_details)
    end
  
  end
  end
  end
