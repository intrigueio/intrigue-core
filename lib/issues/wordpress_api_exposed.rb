module Intrigue
  module Issue
  class WordpressApiExposed < BaseIssue
  
    def self.generate(instance_details={})
      {
        added: "2020-01-01",
        name: "wordpress_api_exposed",
        pretty_name: "Wordpress API Exposed",
        severity: 5,
        category: "misconfiguration",
        status: "confirmed",
        description: "This Wordpress site is exposing its XMLRPC api endpoint.",
        remediation: ".",
        affected_software: [{ :vendor => "Wordpress", :product => "Wordpress" }],
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { type: "remediation", uri: "https://www.greengeeks.com/tutorials/article/how-to-enable-and-disable-xmlrpc-php-in-wordpress-and-why/" }
        ], 
        check: "uri_brute_focused_content"
      }.merge!(instance_details)
    end
  
  end
  end
  end