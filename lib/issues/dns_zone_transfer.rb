module Intrigue
module Issue
class DnsZoneTransfer< BaseIssue

  def self.generate(instance_details={source: "Domain name"})
    to_return = {
      name: "dns_zone_transfer",
      pretty_name: "DNS Zone (AXFR) Transfer Enabled",
      severity: 4,
      status: "confirmed",
      category: "dns",
      description: "AXFR refers to the protocol used during a DNS zone transfer, it is a client-initiated request to get a copy of the zone from the primary server. When we requested an AXFR from this server, the zone was transferred.",
      remediation: "All DNS servers should be configured to only allow zone transfers from trusted IP addresses.",
      affected: [],
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        { type: "description", uri: "https://www.acunetix.com/blog/articles/dns-zone-transfers-axfr/" }
      ]
    }.merge!(instance_details)

  to_return
  end

end
end
end
