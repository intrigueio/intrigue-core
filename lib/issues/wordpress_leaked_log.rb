module Intrigue
  module Issue
  class WordpressLeakedLog < BaseIssue
  
    def self.generate(instance_details={})
      {
        name: "wordpress_leaked_log",
        pretty_name: "Wordpress Leaked Logfile",
        severity: 5,
        status: "confirmed",
        category: "application",
        description: "The site was found to be leaking a commonly known logfile to anonymous users.",
        remediation: "Remove the exposed logfile.",
        affected_software: [{ :vendor => "Wordpress", :product => "Wordpress" }],
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { type: "description", uri: "https://blog.detectify.com/2020/02/26/gehaxelt-how-wordpress-plugins-leak-sensitive-information-without-you-noticing/"}, 
          { type: "description", uri: "https://hackernoon.com/database-security-vs-web-app-leaks-26cd35d9ce5a" }
        ],
        check: "uri_brute_focused_content"
      }.merge!(instance_details)
    end
  
  end
  end
  end
  