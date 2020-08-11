module Intrigue
module Issue
class LeakedVMWareHorizonInfo < BaseIssue

  def self.generate(instance_details={})
    {
      name: "leaked_vmware_horizon_info",
      pretty_name: "Leaked VMWare Horizon Info",
      severity: 4,
      category: "network",
      status: "confirmed",
      description: "This vulnerability CVE-2019-5513, allows an anonymous user to " +
       " gather information about the internal IP address, domain, and configuration" +
       " of the system. Systems are vulnerable in the default configuration.",
      affected: "7.x before 7.8, 7.5.x before 7.5.2, 6.x before 6.2.8",
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        "https://www.vmware.com/security/advisories/VMSA-2019-0003.html"
      ]
    }.merge!(instance_details)
  end

end
end
end
