module Intrigue
  module Issue
  class WordpressDebugLogLeak < BaseIssue

    def self.generate(instance_details={})
      {
        added: "2020-01-01",
        name: "wordpress_debug_log_leak",
        pretty_name: "Wordpress Debug.log Information (Log) Leak",
        severity: 2,
        category: "misconfiguration",
        status: "confirmed",
        description: "A wordpress site was found with an exposed debug.log. These files can contain passwords and other secrets",
        remediation: "Remove the file and/or set permissions on the configuration file to prevent anonymous users being able to read it.",
        affected_software: [{ :vendor => "Wordpress", :product => "Wordpress" }],
        references: [ ], # types: description, remediation, detection_rule, exploit, threat_intel
        task: "uri_brute_focused_content"
      }.merge!(instance_details)
    end

  end
  end
  end