module Intrigue
  module Issue
  class CiscoAsaPathTraversalCve20180296 < BaseIssue
  
    def self.generate(instance_details={})
      {
        added: "2020-01-01",
        pretty_name: "Cisco ASA Path Traversal (CVE-2018-0296)",
        name: "cisco_asa_path_traversal_cve_2018_0296",
        category: "network",
        severity: 2,
        status: "confirmed",
        description: "Cisco ASA path traversal vulnerability",
        remediation:  "Update the device.",
        affected_software: [
          { :vendor => "Cisco", :product => "Adaptive Security Appliance Software" },
          { :vendor => "Cisco", :product => "Adaptive Security Appliance Device Manager" }
        ],
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { type: "description", uri: "https://tools.cisco.com/security/center/content/CiscoSecurityAdvisory/cisco-sa-20180606-asaftd" }, 
          { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2018-0296" }, 
          { type: "exploit", uri: "https://www.exploit-db.com/exploits/44956" }
        ], 
        check: "vuln/cisco_asa_path_traversal_cve_2018_0296"
      }.merge(instance_details)
    end
  
  end
  end
  end