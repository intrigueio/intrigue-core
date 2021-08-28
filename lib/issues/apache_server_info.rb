module Intrigue
module Issue
class ApacheServerInfo < BaseIssue

def self.generate(instance_details={})
  {
    added: "2020-01-01",
    name: "apache_server_info",
    pretty_name: "Apache ServerInfo Information Leak",
    severity: 2,
    status: "confirmed",
    category: "misconfiguration",
    description: "This system was found running mod_info, which leaks details about the configuration of thee server. The module (mod_info) can leak sensitive information from the configuration directives of other Apache modules such as system paths, usernames/passwords, database names, etc. Therefore, this module should only be used in a controlled environment and always with caution.",
    remediation: "Use mod_authz_host to limit access to your server configuration information, or disable the module altogether.",
    affected_software: [
      { :vendor => "Apache", :product => "HTTP Server" },
    ],
    references: [ # types: description, remediation, detection_rule, exploit, threat_intel
      { type: "description", uri: "https://httpd.apache.org/docs/2.4/mod/mod_info.html" },
      { type: "remediation", uri: "https://httpd.apache.org/docs/2.4/mod/mod_info.html" }
    ],
    task: "uri_brute_focused_content"
  }.merge!(instance_details)
end

end
end
end
