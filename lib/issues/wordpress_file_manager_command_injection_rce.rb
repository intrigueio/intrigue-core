module Intrigue
  module Issue
  class WordpressFileManagerCommandInjection RCE < BaseIssue
  
    def self.generate(instance_details={})
      {
        added: "2020-09-01",
        name: "wordpress_file_manager_command_injection_rce",
        pretty_name: "Wordpress File Manager Command Injection RCE",
        severity: 1,
        category: "vulnerability",
        status: "confirmed",
        description: "The file manager plugin, prior to version 6.9, is subject to a simple RCE in the elFinder component.",
        remediation: "Upgrade the plugin and/or install a Wordpress Web Application Firewall like Wordfence or Sucuri",
        affected_software: [{ :vendor => "Mndpsingh287", :product => "Wordpress" }],
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { type: "description", uri: "https://www.wordfence.com/blog/2020/09/700000-wordpress-users-affected-by-zero-day-vulnerability-in-file-manager-plugin/" },
          { type: "exploit", uri: "https://github.com/w4fz5uck5/wp-file-manager-0day/blob/master/elFinder.py" },
        ],
        check: "vuln/wordpress_file_manager_command_injection_rce"
      }.merge!(instance_details)
    end
  
  end
  end
  end