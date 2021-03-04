module Intrigue
module Issue
class HtaccessInfoLeak < BaseIssue

  def self.generate(instance_details={})
    {
      added: "2020-01-01",
      name: "htaccess_info_leak",
      pretty_name: ".htaccess Information Leak",
      severity: 3,
      category: "misconfiguration",
      status: "confirmed",
      description: "A .htaccess file was found exposed on the server. This file can expose sensitive information, including the presence and contents of a .htpasword (secrets) file.",
      remediation: "Change access controls to disallow access to the .htaccess file.",
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
      ]
    }.merge!(instance_details)
  end

end
end
end