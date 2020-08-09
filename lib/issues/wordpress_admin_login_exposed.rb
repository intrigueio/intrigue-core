module Intrigue
  module Issue
  class WordpressAdminLoginExposed < BaseIssue
  
    def self.generate(instance_details={})
      {
        added: "2020-01-01",
        name: "wordpress_admin_login_exposed",
        pretty_name: "Wordpress Admin Login Exposed",
        severity: 5,
        category: "misconfiguration",
        status: "confirmed",
        description: "This Wordpress site is exposing its admin login.",
        remediation: "Disable access to this login for unauthenticated users. Consider whiteelisting.",
        affected_software: [{ :vendor => "Wordpress", :product => "Wordpress" }],
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { type: "remediation", uri: "https://pagely.com/blog/hiding-wordpress-login-page/" }
        ], 
        check: "uri_brute_focused_content"
      }.merge!(instance_details)
    end
  
  end
  end
  end