module Intrigue
module Issue
class ExposedJaspersofPanel < BaseIssue
  
  def self.generate(instance_details={})
    {
      added: "2021-02-01",
      name: "exposed_jaspersoft_panel",
      pretty_name: "Exposed Jaspersoft Login Panel",
      severity: 3, # default
      category: "misconfiguration",
      status: "confirmed",
      description: "A Jaspersoft login panel was discovered. This service does not have strong protection from bruteforce and is a good target for attackers.",
      remediation: "Prevent access to this panel by placing it behind a firewall or otherwise restricting access",
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        { :type => "description", :uri => "https://community.jaspersoft.com/questions/983021/lock-user-account-after-x-failure-attempts" }
      ],
      # task: handled in ident
    }.merge!(instance_details)
  end

end
end
end