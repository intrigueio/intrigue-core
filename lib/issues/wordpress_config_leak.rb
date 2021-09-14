module Intrigue
  module Issue
  class WordpressConfigLeak < BaseIssue
  
    def self.generate(instance_details={})
      {
        added: "2020-01-01",
        name: "wordpress_config_leak",
        pretty_name: "Wordpress Configuration Information Leak",
        severity: 1,
        category: "misconfiguration",
        status: "confirmed",
        description: "A wordpress site was found with an exposed configuration.",
        remediation: "Set permissions on the configuration file to prevent anonymous users being able to read it.",
        affected_software: [{ :vendor => "Wordpress", :product => "Wordpress" }],
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { type: "description", uri: "https://cwe.mitre.org/data/definitions/200.html" },
          { type: "remediation", uri: "https://wordpress.org/support/article/hardening-wordpress/#securing-wp-config-php" }
        ],
        task: "uri_brute_focused_content"
      }.merge!(instance_details)
    end
  
  end
  end
  end