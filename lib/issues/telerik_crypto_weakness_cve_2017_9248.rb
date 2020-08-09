module Intrigue
  module Issue
  class TelerikCryptoWeaknessCve20179248 < BaseIssue
  
    def self.generate(instance_details={})
      {
        added: "2020-01-01",
        name: "telerik_crypto_weakness_cve_2017_9248",
        pretty_name: "Telerik Crypto Weakness (CVE-2017-9248)",
        severity: 1,
        identifiers: [{ "cve" =>  "CVE-2017-9248" }],
        status: "confirmed",
        category: "vulnerability",
        description: "",
        remediation: "Upgrade the Telerik library.",
        affected_software: [ 
          #{ :vendor => "Telerik", :product => "UI" }, # TODO currently only support sitefinity's versioning
          { :vendor => "Telerik", :product => "Sitefinity CMS" }
        ],
        references: [
          { type: "description", uri: "https://www.telerik.com/support/kb/aspnet-ajax/details/cryptographic-weakness" },
          { type: "exploit", uri: "https://captmeelo.com/pentest/2018/08/03/pwning-with-telerik.html"}
        ], 
        check: "vuln/telerik_crypto_weakness_cve_2017_9248"
      }.merge!(instance_details)
    end
  
  end
  end
  end
  