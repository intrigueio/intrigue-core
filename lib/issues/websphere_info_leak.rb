module Intrigue
module Issue
class WebsphereInfoLeak < BaseIssue

  def self.generate(instance_details={})
    {
      added: "2020-01-01",
      name: "websphere_info_leak",
      pretty_name: "IBM Websphere Info Leak",
      identifiers: [],
      severity: 2,
      category: "misconfiguration",
      status: "confirmed",
      description: "This server is exposing sensitive paths.",
      remediation: "Block access to these paths.",
      affected_software: [
        { :vendor => "IBM", :product => "Websphere" }
      ],
      references: [],
      task: "uri_brute_focused_content"
    }.merge!(instance_details)
  end

end
end
end