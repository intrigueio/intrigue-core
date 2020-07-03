module Intrigue
  module Issue
  class VmwareHorizonInfoLeak < BaseIssue
  
    def self.generate(instance_details={})
      {
        name: "vmware_horizon_info_leak",
        pretty_name: "Information Leak in Vmware Horizon (CVE-2019-5513)",
        identifiers: [
          { type: "CVE", name: "CVE-2019-5513" }
        ],
        severity: 3,
        status: "confirmed",
        category: "vulnerability",
        description: "The VMWare Horizon Connection Server is often used as an internet-facing gateway to an organization’s virtual desktop environment (VDI). Until recently, most of these installations exposed the Connection Server’s internal name, the gateway’s internal IP address, and the Active Directory domain to unauthenticated attackers. Information leaks like these are not a huge risk on their own, but combined with more significant vulnerabilities they can make a remote compromise easier.",
        remediation: "Apply the relevant patch for your operating system, or disable RDP if not needed.",
        affected_software: [
          { :vendor => "VMWare", :product => "Horizon View" },
        ],
        references: [
          { type: "description", uri: "https://www.atredis.com/blog/2019/3/15/cve-2019-5513-information-leaks-in-vmware-horizon" }
        ],
        check: "vuln/vmware_horizon_info_leak"
      }.merge!(instance_details)
    end
  
  end
  end
  end
  
  
          
  