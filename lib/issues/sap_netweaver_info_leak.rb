module Intrigue
  module Issue
  class SapNetweaverInfoLeak < BaseIssue
  
    def self.generate(instance_details={})
      {
        added: "2020-01-01",
        name: "sap_netweaver_info_leak",
        pretty_name: "SAP Netweaver Info Leak",
        severity: 2,
        status: "confirmed",
        category: "vulnerability",
        description: "Anonymous users can use a special HTTP request to get information about SAP NetWeaver users. A potential attacker can use the vulnerability in order to reveal information about user names, first and last names, associated emails, and other sensitive infomration/",
        remediation: "Upgrade the instance.",
        affected_software: [ 
          { :vendor => "SAP", :product => "Netweaver" }
        ],
        references: [
          { type: "description", uri: "https://securityaffairs.co/wordpress/52978/hacking/sap-systems-flawed.html" },
          { type: "exploit", uri: "https://www.exploit-db.com/exploits/44647"}
        ], 
        task: "uri_brute_focused_content"
      }.merge!(instance_details)
    end
  
  end
  end
  end
  