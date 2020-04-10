module Intrigue
  module Issue
  class WordpressDebugLogLeak < BaseIssue
  
    def self.generate(instance_details={})
      {
        name: "wordpress_debug_log_leak",
        pretty_name: "Wordpress Debug.log Leak",
        severity: 2,
        category: "application",
        status: "confirmed",
        description: "A wordpress site was found with an exposed debug.log.",
        remediation: "Remove the file and/or set permissions on the configuration file to prevent anonymous users being able to read it.",
        affected_software: [{ :vendor => "Wordpress", :product => "Wordpress" }],
        references: [ ] # types: description, remediation, detection_rule, exploit, threat_intel
      }.merge!(instance_details)
    end
  
  end
  end
  end