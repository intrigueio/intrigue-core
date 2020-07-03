module Intrigue
module Issue
class VulnSharepointCve20190604 < BaseIssue

  def self.generate(instance_details={})
    {
      name: "vulnerability_sharepoint_cve_2019_0604",
      pretty_name: "Vulnerable Microsoft Sharepoint (CVE-2019-0604)",
      identifiers: [
        { type: "CVE", name: "CVE-2019-0604" }
      ],
      severity: 1,
      status: "confirmed",
      category: "vulnerability",
      description: "A remote code execution vulnerability exists in Microsoft SharePoint when the software fails to check the source markup of an application package, aka 'Microsoft SharePoint Remote Code Execution Vulnerability'.",
      remediation: "To comprehensively address CVE-2019-0604 Microsoft is releasing the following security updates: 4462199 for Microsoft SharePoint Server 2019, 4462211 for Microsoft SharePoint Enterprise Server 2016, 4462202 for Microsoft SharePoint Foundation 2013 Service Pack 1, and 4462184 for Microsoft SharePoint Server 2010 Service Pack 2. Microsoft recommends that customers running these versions of SharePoint Server install the updates to be protected from this vulnerability.",
      affected_software: [
        { :vendor => "Microsoft", :product => "Sharepoint Services" },
        { :vendor => "Microsoft", :product => "Sharepoint Server", :version => "2019" },
        { :vendor => "Microsoft", :product => "Sharepoint Enterprise Server", :version => "2016" },
        { :vendor => "Microsoft", :product => "Sharepoint Server", :version => "2013", :update => "sp1" },
        { :vendor => "Microsoft", :product => "Sharepoint Foundation", :version => "2013", :update => "sp1" },
        { :vendor => "Microsoft", :product => "Sharepoint Server", :version => "2010", :update => "sp2" },
        { :vendor => "Microsoft", :product => "Sharepoint Foundation", :version => "2010", :update => "sp2" }
      ],
      references: [
        { type: "description", uri: "https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-0604"},
        { type: "description", uri: "https://portal.msrc.microsoft.com/en-US/security-guidance/advisory/CVE-2019-0604"},
        { type: "description", uri: "https://blog.cloudflare.com/stopping-cve-2019-0604/"},
        { type: "description", uri: "https://www.thezdi.com/blog/2019/12/18/looking-back-at-the-impact-of-cve-2019-0604-a-sharepoint-rce"},
        { type: "exploit", uri: "https://twitter.com/1oopho1e/status/1127916284899995648"},
        { type: "exploit", uri: "https://github.com/k8gege/CVE-2019-0604"},
        { type: "threat_intelligence", uri: "https://unit42.paloaltonetworks.com/actors-still-exploiting-sharepoint-vulnerability-to-attack-middle-east-government-organizations/"},
        { type: "threat_intelligence", uri: "https://www.helpnetsecurity.com/2019/05/13/sharepoint-servers-attack-cve-2019-0604/"}
      ]
    }.merge!(instance_details)
  end

end
end
end


        
