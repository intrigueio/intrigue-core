module Intrigue
    module Issue
    class AccellionCompromisedFta < BaseIssue

    def self.generate(instance_details={})
      {
        added: "2021-01-18",
        name: "accellion_compromised_fta",
        pretty_name: "Accellion compromised secure file transfer appliance",
        severity: 2,
        status: "confirmed",
        category: "compromise",
        description: "Accellion's secure file transfer appliance has been compromised and backdoored by attackers.",
        remediation: "Immediately take down the appliance and perform incident response activities within your network.",
        affected_software: [
          { :vendor => "Accellion", :product => "Secure File Transfer" },
        ],
        references: [
          { type: "description", uri: "https://www.itnews.com.au/news/accellion-hack-behind-reserve-bank-of-nz-data-breach-559642" },
          { type: "threat_intel", uri: "https://www.wired.com/story/accellion-breach-victims-extortion/" },

        ],
        task: "vuln/accellion_compromised_fta"
      }.merge!(instance_details)
    end
    end
    end
    end
