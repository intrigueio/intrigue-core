module Intrigue
module Issue
class ExposedAdminPanelUnauthenticated < BaseIssue

  def self.generate(instance_details={})
    {
      added: "2020-01-01",
      name: "exposed_admin_panel_unauthenticated",
      pretty_name: "Exposed Admin Panel",
      severity: 4, # default
      category: "misconfiguration",
      status: "confirmed",
      description: "An admin panel was discovered. This panel should generally not be exposed to unauthenticated users.",
      remediation: "Prevent access to this panel by placing it behind a firewall or otherwise restricting access.",
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
      ],
      # task: handled in ident
    }.merge!(instance_details)
  end

end
end
end