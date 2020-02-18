module Intrigue
module Issue
class AtlassianFisheyeMostactivecommitersVuln < BaseIssue

  def self.generate(instance_details={})
    {
      name: "atlassian_fisheye_mostactivecommiters_cve_2017_9512",
      pretty_name: "Vulnerable to Atlassian Fisheye mostactivecommiters (CVE-2017-9512)",
      severity: 1,
      category: "network",
      status: "confirmed",
      description: "Vulnerable to Atlassian Fisheye mostactivecommiters.do Information Disclosure (CVE-2017-9512)",
      remediation: "Upgraded your Fisheye and Crucible installations to version 4.4.3 or 4.5.1 or higher.",
      affected: [ "Before version 4.4.1 " ],
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        "https://confluence.atlassian.com/crucible/fisheye-and-crucible-security-advisory-2017-11-29-939939750.html"
      ]
    }.merge!(instance_details)
  end

end
end
end
