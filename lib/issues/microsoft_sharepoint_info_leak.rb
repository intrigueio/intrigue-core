module Intrigue
module Issue
class MicrosoftSharepointInfoLeak < BaseIssue

  def self.generate(instance_details={})
    {
      added: "2020-01-01",
      name: "microsoft_sharepoint_info_leak",
      pretty_name: "Microsoft Sharepoint Info Leak",
      severity: 4,
      category: "application",
      status: "confirmed",
      description: "A server running Sharepoint is misconfigured and exposing potentially sensitive information.",
      remediation: "Adjust the configuration of the server to prevent access to this path.",
      affected_software: [ 
        { :vendor => "Microsoft", :product => "Sharepoint Server" },
        { :vendor => "Microsoft", :product => "Sharepoint Services" }
      ],
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        { type: "description", uri: "https://exchange.xforce.ibmcloud.com/vulnerabilities/31642" },
        { type: "remediation", uri: "https://sharepoint.stackexchange.com/questions/11504/sharepoint-2010-disable-hide-references-to-spsdisco-aspx" },
        { type: "remediation", uri: "https://social.msdn.microsoft.com/Forums/vstudio/en-US/df090d4b-ba9b-4212-a524-e3e2bb50cacc/hiding-asmxwsdl?forum=wcf" }  
      ], 
      check: "uri_brute_focused_content"
    }.merge!(instance_details)
  end

end
end
end