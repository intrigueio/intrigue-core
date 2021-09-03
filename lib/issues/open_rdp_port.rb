module Intrigue
module Issue
class OpenRdpPort < BaseIssue

  def self.generate(instance_details={})
    to_return = {
      added: "2020-01-01",
      name: "open_rdp_port",
      pretty_name: "Exposed RDP Service",
      severity: 2,
      status: "confirmed",
      category: "misconfiguration",
      description: "A system exposing RDP to the Internet was identified.",
      remediation: "Verify that this port should be exposed to the Internet.",
      references: []
    }.merge!(instance_details)

  to_return
  end

end
end
end
