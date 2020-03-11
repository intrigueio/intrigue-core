module Intrigue
  module Issue
  class WordpressUserInfoLeak < BaseIssue
  
    def self.generate(instance_details={})
      {
        name: "wordpress_user_info_leak",
        pretty_name: "Wordpress User Info Leak",
        severity: 4,
        category: "application",
        status: "confirmed",
        description: "This Wordpress site is exposing user information via an api endpoint.",
        remediation: ".",
        affected_software: [ 
          { :vendor => "Wordpress", :product => "Wordpress" }
          ],
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { type: "description", uri: "https://hackerone.com/reports/356047" }
        ]
      }.merge!(instance_details)
    end
  
  end
  end
  end