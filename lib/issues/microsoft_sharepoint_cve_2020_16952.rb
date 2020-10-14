module Intrigue
    module Issue
    class VulnSharepointCve202016952 < BaseIssue
    
      def self.generate(instance_details={})
        {
          added: "2020-10-14",
          name: "microsoft_sharepoint_cve_2020_16952",
          pretty_name: "Vulnerable Microsoft Sharepoint (CVE-2020-16952)",
          identifiers: [
            { type: "CVE", name: "CVE-2020-16952" }
          ],
          severity: 1,
          status: "potential",
          category: "vulnerability",
          description: "A remote code execution vulnerability exists in Microsoft SharePoint when the software fails to check the source markup of an application package. An attacker who successfully exploited the vulnerability could run arbitrary code in the context of the SharePoint application pool and the SharePoint server farm account",
          remediation: "To comprehensively address CVE-2020-16952 Microsoft is releasing the following security updates: 4486677 for Microsoft SharePoint Server 2016, 4486694 for Microsoft SharePoint Foundation 2013 Service Pack 1, 4486676 for Microsoft SharePoint Server 2019. Microsoft recommends that customers running these versions of SharePoint Server install the updates to be protected from this vulnerability.",
          affected_software: [
            { :vendor => "Microsoft", :product => "Sharepoint Server", :version => "2019" },
            { :vendor => "Microsoft", :product => "Sharepoint Enterprise Server", :version => "2016"},
            { :vendor => "Microsoft", :product => "Sharepoint Foundation", :version => "2013", :update => "sp1" },
          ],
          references: [
            { type: "description", uri: "https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-16952"},
            { type: "description", uri: "https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/CVE-2020-16952"},
            { type: "description", uri: "https://srcincite.io/advisories/src-2020-0022/"},
            { type: "exploit", uri: "https://srcincite.io/pocs/cve-2020-16952.py.txt"},
            ]
        }.merge!(instance_details)
      end
    
    end
    end
    end
    
    
            
    