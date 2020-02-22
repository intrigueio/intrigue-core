module Intrigue
module Issue
class TorrentAffIP< BaseIssue

  def self.generate(instance_details={})
    to_return = {
      name: "torrent_affiliated_ip",
      pretty_name: "Torrent Activity Detected",
      severity: 4,
      status: "confirmed",
      category: "reputation",
      description:"This IP is related to known Torrent traffic.",
      remediation: "This IP address related to Torrent should be blocked in case of malicious activity",
    }.merge!(instance_details)

  to_return
  end

end
end
end
