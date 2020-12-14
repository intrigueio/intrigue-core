module Intrigue
    module Issue
    class SolarWindsOrionCodeCompromise < BaseIssue
    
      def self.generate(instance_details={})
    
        to_return = {
          added: "2020-12-14",
          name: "solarwinds_orion_code_compromise",
          pretty_name: "SolarWinds Orion Code Compromise",
          category: "vulnerability",
          severity: 1,
          status: "confirmed",
          description: "SolarWinds Orion products with versions 2019.4 through 2020.2.1 HF1 have been compromised and backdoored.",
          remediation:  "Update the instance",
          affected_software: [
            { :vendor => "SolarWinds", :product => "Orion Platform" },
            { :vendor => "SolarWinds", :product => "Orion Core" }
          ],
          references: [
            { type: "description", uri: "https://cyber.dhs.gov/ed/21-01/" },
            { type: "description", uri: "https://www.zdnet.com/article/microsoft-fireeye-confirm-solarwinds-supply-chain-attack/" }
          ],
          check: "vuln/solarwinds_orion_code_compromise"
        }.merge(instance_details)
        
      to_return
      end
    
    end
    end
    end