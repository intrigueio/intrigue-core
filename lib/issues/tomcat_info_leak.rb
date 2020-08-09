module Intrigue
module Issue
class TomcatInfoLeak < BaseIssue

  def self.generate(instance_details)
    to_return = {
      added: "2020-01-01",
      name: "tomcat_info_leak",
      pretty_name: "Tomcat Info Leak",
      severity: 3,
      status: "confirmed",
      category: "application",
      description: "This server is sensitive information on a status page.",
      remediation: "Remove the file from the server or adjust the access controsl.",
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
  