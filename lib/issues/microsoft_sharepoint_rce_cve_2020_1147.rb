module Intrigue
  module Issue
  class MicrosoftSharepointRceCve20201147 < BaseIssue
  
    def self.generate(instance_details={})
      {
        added: "2020-07-27",
        name: "microsoft_sharepoint_rce_cve_2020_1147",
        pretty_name: "Microsoft Sharepoint RCE (CVE-2020-1147)",
        identifiers: [
          { type: "CVE", name: "CVE-2020-1147" }
        ],
        severity: 4,
        category: "vulnerability",
        status: "potential",
        description: "A remote code execution vulnerability exists in .NET Framework, Microsoft SharePoint, and Visual Studio when the software fails to check the source markup of XML file input, aka '.NET Framework, SharePoint Server, and Visual Studio Remote Code Execution Vulnerability",
        remediation: "Adjust the configuration of the server to prevent access to this path.",
        affected_software: [ 
          { :vendor => "Microsoft", :product => "Sharepoint Server" },
          { :vendor => "Microsoft", :product => "Sharepoint Services" }
        ],
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { type: "description", uri: "https://portal.msrc.microsoft.com/en-US/security-guidance/advisory/CVE-2020-1147" },
          { type: "exploit", uri: "https://srcincite.io/blog/2020/07/20/sharepoint-and-pwn-remote-code-execution-against-sharepoint-server-abusing-dataset.html" },
        
        ]
      }.merge!(instance_details)
    end
  
  end
  end
  end