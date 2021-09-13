module Intrigue
  module Issue
  class ApacheServerStatus < BaseIssue

    def self.generate(instance_details={})
      {
        added: "2020-01-01",
        name: "apache_server_status",
        pretty_name: "Apache ServerStatus information Leak",
        severity: 3,
        status: "confirmed",
        category: "misconfiguration",
        description: "This system was found running mod_status, which leaks information about the configuration of this server",
        remediation: "Use mod_authz_host to limit access to your server configuration information, or disable the module altogether.",
        affected_software: [
          { :vendor => "Apache", :product => "HTTP Server"},
        ],
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { type: "description", uri: "https://httpd.apache.org/docs/2.4/mod/mod_status.html" },
          { type: "remediation", uri: "https://httpd.apache.org/docs/2.4/mod/mod_status.html" }
        ],
        task: "uri_brute_focused_content"
      }.merge!(instance_details)
    end

  end
  end
  end


