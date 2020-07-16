module Intrigue
  module Issue
  class CitrixNetscalerCve20208193 < BaseIssue
  
    def self.generate(instance_details={})
      {
        name: "citrix_netscaler_rce_cve_2020_8193",
        pretty_name: "Vulnerable Citrix Netscaler (CVE-2020-8193)",
        identifiers: [
          { type: "CVE", name: "CVE-2020-8193" }
        ],
        severity: 1,
        category: "vulnerability",
        status: "confirmed",
        description: "An authorization bypass vulnerability exists in Citrix ADC and NetScaler Gateway devices. An unauthenticated remote attacker with access to the NSIP/management interface can exploit this to bypass authorization. (CVE-2020-8193)",
        affected_software: [
          { :vendor => "Citrix", :product => "NetScaler Gateway (Management Inteface)" }
        ],
        references: [
          { type: "description", uri: "https://blog.unauthorizedaccess.nl/2020/07/07/adventures-in-citrix-security-research.html" },
          { type: "description", uri: "https://www.tenable.com/plugins/nessus/138212" },
          { type: "exploit", uri: "https://blog.unauthorizedaccess.nl/2020/07/07/adventures-in-citrix-security-research.html" }
        ]
      }.merge!(instance_details)
    end
  
  end
  end
  end
  
  
          
  