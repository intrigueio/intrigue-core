module Intrigue
  module Issue
  class SapReconVulnCve20206287 < BaseIssue
  
    def self.generate(instance_details={})
      {
        added: "2020-01-01",
        name: "sap_recon_vuln_cve_2020_6287",
        pretty_name: "SAP RECON Vuln (CVE-2020-6287)",
        identifiers: [
          { type: "CVE", name: "CVE-2020-6287" }
        ],        
        severity: 1,
        status: "confirmed",
        category: "vulnerability",
        description: "A successful exploit of RECON could give an unauthenticated attacker full access to the affected SAP system. This includes the ability to modify financial records, steal personally identifiable information (PII) from employees, customers and suppliers, corrupt data, delete or modify logs and traces and other actions that put essential business operations, cybersecurity and regulatory compliance at risk.",
        remediation: "Upgrade the instance.",
        affected_software: [ 
          { :vendor => "SAP", :product => "Netweaver" }
        ],
        references: [
          { type: "description", uri: "https://www.onapsis.com/recon-sap-cyber-security-vulnerability" },
        ]
        }.merge!(instance_details)
    end
  
  end
  end
  end
  