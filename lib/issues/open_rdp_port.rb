module Intrigue
module Issue
class OpenRdpPort < BaseIssue

  def self.generate(instance_details={})
    to_return = {
      added: "2020-01-01",
      name: "open_rdp_port",
      pretty_name: "Open RDP Port",
      severity: 3,
      status: "confirmed",
      category: "application",
      description: "A system exposing RDP to the Internet was identified.",
      remediation: "Verify that this port should be exposed to the Internet.",
      references: []
    }.merge!(instance_details)

  to_return
  end

end
end
end
