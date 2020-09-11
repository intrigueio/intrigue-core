module Intrigue
  module Issue
  class VulnExchangeCve202016875 < BaseIssue

    def self.generate(instance_details={})
      {
        added: "2020-09-11",
        name: "microsoft_exchange_cve_2020_0688",
        pretty_name: "Microsoft Exchange Server DlpUtils AddTenantDlpPolicy Remote Code Execution Vulnerabilit (CVE-2020-16875)",
        identifiers: [
          { type: "CVE", name: "CVE-2020-16875" }
        ],
        severity: 1,
        status: "potential",
        category: "vulnerability",
        description: "This vulnerability allows remote attackers to execute arbitrary code on affected installations of Exchange Server. Authentication is required to exploit this vulnerability. The specific flaw exists within the processing of the New-DlpPolicy cmdlet. The issue results from the lack of proper validation of user-supplied template data when creating a dlp policy. An attacker can leverage this vulnerability to execute code in the context of SYSTEM.",
        remediation: "",
        affected_software: [
          { :vendor => "Microsoft", :product => "Exchange Server", :version => "2016", :update => "Cumulative Update 16" },
          { :vendor => "Microsoft", :product => "Exchange Server", :version => "2016", :update => "Cumulative Update 17" },
          { :vendor => "Microsoft", :product => "Exchange Server", :version => "2019", :update => "Cumulative Update 5" },
          { :vendor => "Microsoft", :product => "Exchange Server", :version => "2019", :update => "Cumulative Update 6" }
        ],
        references: [
          { type: "description", uri: "https://portal.msrc.microsoft.com/en-us/security-guidance/advisory/CVE-2020-16875"},
          { type: "description", uri: "https://srcincite.io/advisories/src-2020-0019/"},
        ],
        check: "vuln/microsoft_exchange_cve_2020_16875"
      }.merge!(instance_details)
    end

  end
  end
  end
