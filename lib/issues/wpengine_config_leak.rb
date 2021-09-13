module Intrigue
  module Issue
  class WpEngineConfigLeak < BaseIssue

    def self.generate(instance_details={})
      {
        added: "2020-01-01",
        name: "wpengine_config_leak",
        pretty_name: "WPEngine Config Leak",
        severity: 1,
        category: "misconfiguration",
        status: "confirmed",
        description: "A wordpress site was found with an exposed configuration.",
        remediation: "Set permissions on the configuration file to prevent anonymous users being able to read it.",
        affected_software: [{ :vendor => "WPEngine", :product => "WPEngine" }],
        references: [ ], # types: description, remediation, detection_rule, exploit, threat_intel
        task: "uri_brute_focused_content"
      }.merge!(instance_details)
    end

  end
  end
  end