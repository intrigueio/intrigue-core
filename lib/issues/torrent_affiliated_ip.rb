module Intrigue
module Issue
class TorrentAffIP< BaseIssue

  def self.generate(instance_details={})
    to_return = {
      added: "2020-01-01",
      name: "torrent_affiliated_ip",
      pretty_name: "Torrent Activity Detected",
      severity: 4,
      status: "confirmed",
      category: "threat",
      description:"This IP is related to known BitTorrent traffic. This can be indicative of a compromised or otherwise abused host.",
      remediation: "This IP address related to BitTorrent should be blocked in case of malicious activity",
    }.merge!(instance_details)

  to_return
  end

end
end
end
