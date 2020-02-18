module Intrigue
module Issue
class RailsInformationDisclosure < BaseIssue

  def self.generate(instance_details={})
    {
      name: "rails_information_disclosure_cve_2019-5418",
      pretty_name: "Rails information disclosure",
      severity: 1,
      category: "network",
      status: "confirmed",
      description:"This issue described in CVE-2019-5418, allows an anonymous user" +
       " to gather internal files from the affected system, up to and including the" +
       " /etc/shadow file, depending on permissions. The 'render' command must be" +
       " used to render a file from disk in order to be vulnerable",
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        "https://github.com/mpgn/Rails-doubletap-RCE"
      ]
    }.merge!(instance_details)
  end

end
end
end
