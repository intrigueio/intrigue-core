module Intrigue
    module Issue
    class WordpressUserInfoLeak < BaseIssue
    
      def self.generate(instance_details={})
        {
          added: "2020-22-10",
          name: "wordpress_loginizer_cve_2020_27615",
          pretty_name: "Wordpress Loginizer Plugin SQL Injection - CVE-2020-27615",
          severity: 1,
          category: "vulnerability",
          status: "confirmed",
          description: "This Wordpress site has a vulnerable version of Loginizer plugin.",
          remediation: "Update to Loginizer 1.6.4 or later",
          affected_software: [{ :vendor => "Wordpress", :product => "Loginizer" }],
          references: [ # types: description, remediation, detection_rule, exploit, threat_intel
            { type: "description", uri: "https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-27615" },
            {type: "description", uri: "https://wpdeeply.com/loginizer-before-1-6-4-sqli-injection/"}
          ], 
          check: "vuln/wordpress_loginizer_cve_2020_27615"
        }.merge!(instance_details)
      end
    
    end
    end
    end