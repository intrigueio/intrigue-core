module Intrigue
  module Issue
  class VulnerableGlobalProtectCve20191579 < BaseIssue
  
    def self.generate(instance_details={})
      {
        name: "vulnerable_globalprotect_cve_2019_1579",
        pretty_name: "Vulnerable PaloAlto GlobalProtect (CVE-2019-1579)",
        identifiers: [
          { type: "CVE", name: "CVE-2019-1579" }
        ],        
        severity: 1,
        category: "vulnerability",
        status: "confirmed",
        description: "A known format string vulnerability in the PAN SSL Gateway was discovered, which handles client/server SSL handshakes. More specifically, the vulnerability exists because the gateway passes the value of a particular parameter to snprintf in an unsanitized, and exploitable, fashion. An unauthenticated attacker could exploit the vulnerability by sending a specially crafted request to a vulnerable SSL VPN target in order to remotely execute code on the system.",
        remediation: "Apply the Vendor-provided patch: https://docs.paloaltonetworks.com/pan-os",
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { type: "description", uri: "https://www.tenable.com/blog/cve-2019-1579-critical-pre-authentication-vulnerability-in-palo-alto-networks-globalprotect-ssl" },
          { type: "remediation", uri: "https://docs.paloaltonetworks.com/pan-os" }
        ], 
        affected_software: [
          { :vendor => "PaloAltoNetworks", :product => "GlobalProtect" },
        ],
        check: "vuln/paloalto_globalprotect_check"
      }.merge!(instance_details)
    end
  
  end
  end
  end
  
  
          