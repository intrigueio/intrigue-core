module Intrigue
  module Issue
  class WordpressConfigLeak < BaseIssue
  
    def self.generate(instance_details={})
      {
        name: "wordpress_config_leak",
        pretty_name: "Microsoft Sharepoint Info Leak",
        severity: 1,
        category: "application",
        status: "confirmed",
        description: "A wordpress site was found with an exposed configuration.",
        remediation: "Remove the exposed configuration file.",
        affected_software: [ 
          { :vendor => "Wordpress", :product => "Wordpress" }
          ],
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { type: "description", uri: "https://exchange.xforce.ibmcloud.com/vulnerabilities/31642" },
          { type: "remediation", uri: "https://sharepoint.stackexchange.com/questions/11504/sharepoint-2010-disable-hide-references-to-spsdisco-aspx" },
          { type: "remediation", uri: "https://social.msdn.microsoft.com/Forums/vstudio/en-US/df090d4b-ba9b-4212-a524-e3e2bb50cacc/hiding-asmxwsdl?forum=wcf" }
        ]
      }.merge!(instance_details)
    end
  
  end
  end
  end