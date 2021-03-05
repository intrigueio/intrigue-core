module Intrigue
  module Issue
  class SonicwallCve20205135 < BaseIssue

    def self.generate(instance_details={})
      {
        added: "2020-10-16",
        name: "sonicwall_cve_2020_5135",
        pretty_name: "SonicWall VPN Portal Stack-based Buffer Overflow Vulnerability (CVE-2020-5135)",
        identifiers: [
          { type: "CVE", name: "CVE-2020-5135" }
        ],
        severity: 1,
        status: "potential",
        category: "vulnerability",
        description: "CVE-2020-5135 is a stack-based buffer overflow vulnerability in the VPN Portal of SonicWall’s Network Security Appliance. A remote, unauthenticated attacker could exploit the vulnerability by sending a specially crafted HTTP request with a custom protocol handler to a vulnerable device. At a minimum, successful exploitation would result in a denial of service condition against the exploited device, exhausting its resources. Remote code execution is likely feasible with additional footwork.",
        remediation: "SonicWall published a patch for this vulnerability. For remediation, update to the latest version of SonicOS firmware.",
        affected_software: [
          { :vendor => "SonicWall", :product => "SonicOS"},
        ],
        references: [
          { type: "description", uri: "https://psirt.global.sonicwall.com/vuln-detail/SNWLID-2020-0010"},
          { type: "description", uri: "https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-5135"},
          { type: "description", uri: "https://www.tenable.com/blog/cve-2020-5135-critical-sonicwall-vpn-portal-stack-based-buffer-overflow-vulnerability"},
        ],
        task: "vuln/sonicwall_cve_2020_5135"
      }.merge!(instance_details)
    end

  end
  end
  end
