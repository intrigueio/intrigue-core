module Intrigue
module Issue
class PhpmyadminSetupFiles < BaseIssue

  def self.generate(instance_details={})
    {
      added: "2020-01-01",
      name: "phpmymyadmin_setup_files",
      pretty_name: "PhpMyAdmin Setup Files",
      severity: 4,
      category: "application",
      status: "confirmed",
      description: "A server running PhpMyAdmin was found with a setup file",
      remediation: "Remove the file.",
      affected_software: [ 
        { :vendor => "PhpMyAdmin", :product => "PhpMyAdmin" }
      ],
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        { type: "remediation", uri: "https://security.stackexchange.com/questions/40291/strange-requests-to-web-server" },
        { type: "remediation", uri: "https://serverfault.com/questions/202822/how-to-thwart-phpmyadmin-attacks"}
      ], 
      check: "uri_brute_focused_content"
    }.merge!(instance_details)
  end

end
end
end