module Intrigue
  module Issue
  class IceWarpCve20208512 < BaseIssue

    def self.generate(instance_details={})
      {
        added: "2020-09-10",
        name: "icewarp_xss_cve_2020_8512",
        pretty_name: "IceWarp WebMail XSS (CVE-2020-8512)",
        identifiers: [
          { type: "CVE", name: "CVE-2020-8512" }
        ],
        severity: 3,
        category: "vulnerability",
        status: "potential",
        description: "A cross-site scripting (XSS) vulnerability exists in IceWarp Webmail Server through 11.4.4.1. An attacker can use XSS to send a malicious script to an unsuspecting user. The end user’s browser has no way to know that the script should not be trusted, and will execute the script. Because it thinks the script came from a trusted source, the malicious script can access any cookies, session tokens, or other sensitive information retained by the browser and used with that site.",
        affected_software: [
          { :vendor => "IceWarp", :product => "IceWarp" }
        ],
        references: [
          { type: "description", uri: "https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-8512" },
          { type: "description", uri: "https://owasp.org/www-community/attacks/xss/" },
          { type: "exploit", uri: "https://www.exploit-db.com/exploits/47988" }
        ],
        check: "vuln/icewarp_xss_cve_2020_8512"
      }.merge!(instance_details)
    end

  end
  end
  end
