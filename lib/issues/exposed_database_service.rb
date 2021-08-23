module Intrigue
module Issue
class ExposedDatabaseService < BaseIssue

  def self.generate(instance_details={})
    {
      added: "2020-09-25",
      name: "exposed_database_service",
      pretty_name: "Exposed Database Service",
      severity: 3,
      category: "misconfiguration",
      status: "confirmed",
      description: "A database service was found listening on the network.",
      remediation: "Prevent access to this service if it should not be exposed.",
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
      ],
      # task: handled in ident
    }.merge!(instance_details)
  end

end
end
end