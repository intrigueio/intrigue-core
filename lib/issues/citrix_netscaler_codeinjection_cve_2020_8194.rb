module Intrigue
  module Issue
  class CitrixNetscalerCve20208194 < BaseIssue

    def self.generate(instance_details={})
      {
        added: "2020-09-16",
        name: "citrix_netscaler_codeinjection_cve_2020_8194",
        pretty_name: "Vulnerable Citrix Netscaler (CVE-2020-8194)",
        identifiers: [
          { type: "CVE", name: "CVE-2020-8194" }
        ],
        severity: 3,
        category: "vulnerability",
        status: "confirmed",
        description: "A reflected code injection in Citrix ADC and Citrix Gateway versions before 13.0-58.30, 12.1-57.18, 12.0-63.21, 11.1-64.14 and 10.5-70.18 and Citrix SDWAN WAN-OP versions before 11.1.1a, 11.0.3d and 10.2.7 allows the modification of a file download.",
        affected_software: [
          { :vendor => "Citrix", :product => "NetScaler Gateway (Management Inteface)" }
        ],
        references: [
          { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2020-8194" },
          { type: "exploit", uri: "https://www.rapid7.com/db/vulnerabilities/citrix-adc-cve-2020-8194" }
        ]
      }.merge!(instance_details)
    end

  end
  end
  end
