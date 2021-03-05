module Intrigue
  module Issue
  class LaravelEnvFile < BaseIssue
  
    def self.generate(instance_details={})
      {
        added: "2020-01-01",
        name: "laravel_env_file",
        pretty_name: "Exposed Laravel .env File",
        severity: 1,
        category: "misconfiguration",
        status: "potential",
        description: "This server is exposing a sensitive configuration file for Laravel!",
        remediation: "Disable access for anonymous users and rotate passwords.",
        affected_software: [ 
          { :vendor => "Laravel", :product => "Laravel" }
        ],
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { type: "description", uri: "https://dev.to/_shahroznawaz/laravel-env-files-exposed-in-browsers-28l" },
          { type: "remediation", uri: "https://laracasts.com/discuss/channels/laravel/in-shared-hosting-environment-how-to-hide-env-file-from-public" } 
        ], 
        task: "uri_brute_focused_content"
      }.merge!(instance_details)
    end
  
  end
  end
  end
  
  
          