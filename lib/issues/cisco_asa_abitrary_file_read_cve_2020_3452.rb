module Intrigue
  module Issue
  class CiscoAsaArbitraryFileReadCve20203452 < BaseIssue
  
    def self.generate(instance_details={})
      {
        added: "2020-07-22",
        pretty_name: "Cisco ASA Arbitrary File Read (CVE-2020-3452)",
        name: "cisco_asa_abitrary_file_read_cve_2020_3452",
        category: "vulnerability",
        severity: 1,
        status: "confirmed",
        description: "Cisco ASA vulnerability, allows reading of arbitrat ",
        remediation:  "Update the device.",
        affected_software: [
          { :vendor => "Cisco", :product => "Adaptive Security Appliance Software" },
          { :vendor => "Cisco", :product => "Adaptive Security Appliance Device Manager" }
        ],
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { type: "description", uri: "https://tools.cisco.com/security/center/content/CiscoSecurityAdvisory/cisco-sa-asaftd-ro-path-KJuQhB86" }, 
          { type: "description", uri: "https://twitter.com/ptswarm/status/1285974719821500423/photo/1" }
        ], 
        check: "vuln/cisco_asa_abitrary_file_read_cve_2020_3452"
      }.merge(instance_details)
    end
  
  end
  end
  end