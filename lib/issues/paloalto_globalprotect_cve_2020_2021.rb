module Intrigue
  module Issue
  class PaloAltoGlobalProtectCve20202021 < BaseIssue
  
    def self.generate(instance_details={})
      {
        added: "2020-07-03",
        name: "paloalto_globalprotect_cve_2019_2021",
        pretty_name: "PaloAlto GlobalProtect Vulnerability (CVE-2020-2021)",
        identifiers: [
          { type: "CVE", name: "CVE-2020-2021" }
        ],        
        severity: 1,
        category: "vulnerability",
        status: "potential",
        description: "An authentication bypass vulnerability affecting PaloAlto GlobalProtect VPNs",
        remediation: "Apply the Vendor-provided patch: https://docs.paloaltonetworks.com/pan-os",
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { type: "description", uri: "https://security.paloaltonetworks.com/CVE-2020-2021" },
          { type: "remediation", uri: "https://docs.paloaltonetworks.com/pan-os" }
        ],
        affected_software: [
          { :vendor => "PaloAltoNetworks", :product => "GlobalProtect" },
        ],
        check: "vuln/paloalto_globalprotect_check_cve2020_2021"
      }.merge!(instance_details)
    end
  
  end
  end
  end
  
  
          