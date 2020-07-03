module Intrigue
  module Issue
  class WpEngineConfigLeak < BaseIssue
  
    def self.generate(instance_details={})
      {
        name: "wpengine_config_leaka",
        pretty_name: "WPEngine Config Leak",
        severity: 1,
        category: "application",
        status: "confirmed",
        description: "A wordpress site was found with an exposed configuration.",
        remediation: "Set permissions on the configuration file to prevent anonymous users being able to read it.",
        affected_software: [{ :vendor => "WPEngine", :product => "WPEngine" }],
        references: [ ], # types: description, remediation, detection_rule, exploit, threat_intel
        check: "uri_brute_focused_content"
      }.merge!(instance_details)
    end
  
  end
  end
  end