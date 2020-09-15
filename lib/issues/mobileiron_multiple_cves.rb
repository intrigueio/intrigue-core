module Intrigue
  module Issue
  class MobileIronCve202015506 < BaseIssue

    def self.generate(instance_details={})
      {
        added: "2020-09-15",
        name: "mobileiron_multiple_cves",
        pretty_name: "MobileIron Multiple CVEs",
        identifiers: [
          { type: "CVE", name: "CVE-2020-15505" },
          { type: "CVE", name: "CVE-2020-15506" },
          { type: "CVE", name: "CVE-2020-15507" },
        ],
        severity: 1,
        category: "vulnerability",
        status: "potential",
        description: "Multiple vulnerabilities in MobileIron Core, Connector, Cloud, Sentry and Reporting Database (RDB) versions 10.6 and earlier could allow an attacker to execute remote exploits without authentication.",
        remediation: "Apply patches released on June 15,2020",
        affected_software: [
          { :vendor => "MobileIron", :product => "Core" }
        ],
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { type: "description", uri: "https://nvd.nist.gov/vuln/search/results?form_type=Advanced&cves=on&cpe_version=cpe%3a%2fa%3amobileiron%3acore%3a10.6" },
          { type: "exploit", uri: "https://blog.orange.tw/2020/09/how-i-hacked-facebook-again-mobileiron-mdm-rce.html" },
          { type: "remediation", uri: "https://www.mobileiron.com/en/blog/mobileiron-security-updates-available" },

        ],
        check: "vuln/mobileiron_multiple_cves"
      }.merge!(instance_details)
    end

  end
  end
  end
