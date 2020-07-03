module Intrigue
  module Issue
  class PhpInfoLeak < BaseIssue
  
    def self.generate(instance_details)
      to_return = {
        name: "php_info_leak",
        pretty_name: "PHP Info Leak",
        severity: 3,
        status: "confirmed",
        category: "network",
        description: "This server is exposing a phpinfo.php file, which provides detailed information about the configuration of the server.",
        remediation: "Remove the file from the server.",
        affected_software: [
          { :vendor => "PHP", :product => "PHP" }
        ],
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        ],
        # task: handled in ident
      }.merge!(instance_details)
  
    to_return
    end
  
  end
  end
  end
  