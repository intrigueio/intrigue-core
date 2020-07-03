module Intrigue
module Issue
class TomcatConfig < BaseIssue

  def self.generate(instance_details)
    to_return = {
      name: "tomcat_config",
      pretty_name: "Tomcat Config",
      severity: 4,
      status: "confirmed",
      category: "network",
      description: "This server is exposing a sensitive path on tomcat.",
      remediation: "Adjust access congrols on this server to remove access to this path.",
      affected_software: [
        { :vendor => "Apache", :product => "Tomcat" }
      ],
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
      ],
      # task: handled in ident
    }.merge!(instance_details)

  to_return
  end

end
end
end