module Intrigue
module Issue
class PaloAltoGlobalProtect < BaseIssue

  def self.generate(instance_details={})
    {
      name: "palo_alto_global_protect_vuln",
      pretty_name: "Vulnerable Palo Alto Global Protect",
      severity: 1,
      category: "network",
      status: "confirmed",
      description: "This server is vulnerable to an unauthenticated RCE bug announced in July 2019, named CVE-2019-1579.",
      affected: "Version 7.1 : <= 7.1.18 \n Version 8.0 <= 8.0.11-h1 \n Version 8.1 <= 8.1.2",
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        "https://security.paloaltonetworks.com/CVE-2019-1579"
      ]
    }.merge!(instance_details)
  end

end
end
end
