module Intrigue
  module Issue
  class WordpressConfigLeak < BaseIssue
  
    def self.generate(instance_details={})
      {
        name: "wordpress_config_leak",
        pretty_name: "Wordpress Configuraton Info Leak",
        severity: 1,
        category: "application",
        status: "confirmed",
        description: "A wordpress site was found with an exposed configuration.",
        remediation: "Set permissions on the configuration file to prevent anonymous users being able to read it.",
        affected_software: [{ :vendor => "Wordpress", :product => "Wordpress" }],
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
      }.merge!(instance_details)
    end
  
  end
  end
  end