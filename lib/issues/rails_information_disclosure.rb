module Intrigue
module Issue
class RailsInformationDisclosure < BaseIssue

  def self.generate(instance_details={})
    {
      name: "rails_information_disclosure_cve_2019_5418",
      pretty_name: "Rails Sensitive File Disclosure (CVE-2019-5418)",
      severity: 1,
      category: "vulnerability",
      status: "confirmed",
      description:"A rails instance was found vulnerable to CVE-2019-5418, allowing an anonymous user" +
       " to gather internal files from the affected system, up to and including the" +
       " /etc/shadow file, depending on permissions. The 'render' command must be" +
       " used to render a file from disk in order to be vulnerable",
      affected_software: [ 
        { :vendor => "Ruby", :product => "Rails" }
      ],
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        { type: "description", uri: "https://github.com/mpgn/Rails-doubletap-RCE" }
      ], 
      check: "vuln/rails_file_exposure"
    }.merge!(instance_details)
  end

end
end
end
