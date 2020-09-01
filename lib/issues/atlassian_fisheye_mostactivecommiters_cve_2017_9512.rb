module Intrigue
module Issue
class AtlassianFisheyeMostactivecommitersVuln < BaseIssue

  def self.generate(instance_details={})
    {
      added: "2020-01-01",
      name: "atlassian_fisheye_mostactivecommiters_cve_2017_9512",
      pretty_name: "Vulnerable Atlassian Fisheye (CVE-2017-9512)",
      identifiers: [
        { type: "CVE", name: "CVE-2017-9512" }
      ],
      severity: 1,
      category: "vulnerability",
      status: "confirmed",
      description: "Vulnerable to Atlassian Fisheye mostactivecommiters.do Information Disclosure",
      remediation: "Upgrade your Fisheye and Crucible installations to version 4.4.3 or 4.5.1 or higher.",
      affected_software: [ 
        { :vendor => "Atlassian", :product => "Fisheye", :version_from => "0", :version_to => "4.4.1" } ],
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        { type: "description", uri: "https://confluence.atlassian.com/crucible/fisheye-and-crucible-security-advisory-2017-11-29-939939750.html" }
      ], 
      check: "vuln/atlassian_fisheye_mostactivecommiters_disclosure"
    }.merge!(instance_details)
  end

end
end
end
