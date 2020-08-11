module Intrigue
  module Issue
  class CiscoAsaLimitedFileReadCve20203452 < BaseIssue
  
    def self.generate(instance_details={})
      {
        added: "2020-07-22",
        pretty_name: "Cisco ASA Limited File Read (CVE-2020-3452)",
        name: "cisco_asa_limited_file_read_cve_2020_3452",
        category: "vulnerability",
        severity: 2,
        status: "confirmed",
        description: "A vulnerability in the web services interface of Cisco Adaptive Security Appliance (ASA) Software and Cisco Firepower Threat Defense (FTD) Software could allow an unauthenticated, remote attacker to conduct directory traversal attacks and read sensitive files on a targeted system. The vulnerability is due to a lack of proper input validation of URLs in HTTP requests processed by an affected device. An attacker could exploit this vulnerability by sending a crafted HTTP request containing directory traversal character sequences to an affected device. A successful exploit could allow the attacker to view arbitrary files within the web services file system on the targeted device. The web services file system is enabled when the affected device is configured with either WebVPN or AnyConnect features. This vulnerability cannot be used to obtain access to ASA or FTD system files or underlying operating system (OS) files.",
        remediation:  "Update the device.",
        affected_software: [
          { :vendor => "Cisco", :product => "Adaptive Security Appliance Software" },
          { :vendor => "Cisco", :product => "Adaptive Security Appliance Device Manager" }
        ],
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { type: "description", uri: "https://tools.cisco.com/security/center/content/CiscoSecurityAdvisory/cisco-sa-asaftd-ro-path-KJuQhB86" }, 
          { type: "description", uri: "https://twitter.com/ptswarm/status/1285974719821500423/photo/1" }
        ], 
        check: "vuln/cisco_asa_limited_file_read_cve_2020_3452"
      }.merge(instance_details)
    end
  
  end
  end
  end