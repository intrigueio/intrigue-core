module Intrigue
module Issue
class JoomlaAgoraBypassSqli < BaseIssue

  def self.generate(instance_details={})
    {
      added: "2020-01-01",
      name: "vulnerable_joomla_agora_bypass_sqli",
      pretty_name: "Joomla Agora Bypass Sqlis",
      severity: 4,
      category: "vulnerability",
      status: "confirmed",
      description: "A server running Joomla Agora was identified as vulnerable to sql injection.",
      remediation: "Upgrade the Agora extension or remove it.",
      affected_software: [ 
        { :vendor => "Joomla", :product => "Joomla!" }
        ],
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        { type: "description", uri: "https://packetstormsecurity.com/files/151619/Joomla-Agora-4.10-Bypass-SQL-Injection.html" },
      ], 
      check: "uri_brute_focused_content"
    }.merge!(instance_details)
  end

end
end
end