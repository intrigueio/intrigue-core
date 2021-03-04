module Intrigue
module Issue
class VulnerablePulseSecure < BaseIssue

  def self.generate(instance_details={})
    {
      added: "2020-01-01",
      name: "vulnerable_pulse_secure",
      pretty_name: "Pulse Secure Info Leak (Version and Configuration)",
      identifiers: [],
      severity: 3,
      category: "vulnerability",
      status: "confirmed",
      description: "A file exposed publicly on the Pulse Secure VPN server exposes specific version and configuration information.",
      remediation: "Remove the file or block access.",
      affected_software: [
        { :vendor => "PulseSecure", :product => "Pulse Connect Secure" }
      ],
      references: [],
      check: "uri_brute_focused_content"
    }.merge!(instance_details)
  end

end
end
end