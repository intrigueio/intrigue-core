module Intrigue
  module Issue
  class VulnerablePaloAltoGlobalProtectCve20202021 < BaseIssue
  
    def self.generate(instance_details={})
      {
        name: "vulnerable_paloalto_globalprotect_cve_2019_2021",
        pretty_name: "Vulnerable PaloAlto GlobalProtect (CVE-2020-2021)",
        identifiers: [
          { type: "CVE", name: "CVE-2020-2021" }
        ],        
        severity: 1,
        category: "vulnerability",
        status: "potential",
        description: "An authentication bypass vulnerability affecting PaloAlto GlobalProtect VPNs",
        remediation: "Apply the Vendor-provided patch: https://docs.paloaltonetworks.com/pan-os",
        affected: [ 
          { :vendor => "PaloAltoNetworks", :product => "GlobalProtect" },
        ],
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { type: "description", uri: "https://security.paloaltonetworks.com/CVE-2020-2021" },
          { type: "remediation", uri: "https://docs.paloaltonetworks.com/pan-os" }
        ]
      }.merge!(instance_details)
    end
  
  end
  end
  end
  
  
          