module Intrigue
  module Issue
  class JForumUserInfoLeak < BaseIssue
  
    def self.generate(instance_details={})
      {
        name: "jforum_user_info_leak",
        pretty_name: "JForum User Information Leak",
        severity: 3,
        category: "application",
        status: "confirmed",
        description: "A http request can be sent to determine if a user exists in the system.",
        remediation: "Upgrade the software",
        affected_software: [ 
          { :vendor => "Jforum", :product => "Jforum" },
        ],
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { type: "description", uri: "https://www.criticalstart.com/information-disclosure-in-jforum-2-1-x-syntax/"}
        ]
        
      }.merge!(instance_details)
    end
  
  end
  end
  end