module Intrigue
module Issue
class LeakedVMWareHorizonInfo < BaseIssue

  def self.generate(instance_details={})
    {
      name: "vulnerability_webmin_cve_2019_15107",
      pretty_name: "Vulnerable Webmin Install",
      severity: 1,
      category: "network",
      status: "potential",
      description: "server found vulnerable to an unauthenticated admin password reset.",
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        "https://nvd.nist.gov/vuln/detail/CVE-2019-15107"
      ]
    }.merge!(instance_details)
  end

end
end
end
