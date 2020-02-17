module Intrigue
module Issue
class DnsZoneTransfer< BaseIssue

  def self.generate(instance_details={source: "Domain name"})
    to_return = {
      name: "dns_zone_transfer",
      pretty_name: "DNS Zone (AXFR) Transfer Enabled",
      severity: 4,
      status: "confirmed",
      category: "network",
      description: "AXFR refers to the protocol used during a DNS zone transfer, It is a client-initiated request to get a copy of the zone from the primary server",
      remediation: "DNS server should be configured to only allow zone transfers from trusted IP addresses.",
      affected: [],
      references: ["https://www.acunetix.com/blog/articles/dns-zone-transfers-axfr/" # types: description, remediation, detection_rule, exploit, threat_intel
      ]
    }.merge!(instance_details)

  to_return
  end

end
end
end
