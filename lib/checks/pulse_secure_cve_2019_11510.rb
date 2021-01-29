
module Intrigue

    module Issue
      class PulseSecureCve201911510 < BaseIssue
        def self.generate(instance_details={})
        {
          added: "2020-11-19",
          name: "pulse_secure_cve_2019_11510",
          pretty_name: "Pulse Secure Arbitrary File Reading CVE-2019-11510",
          severity: 1,
          category: "vulnerability",
          status: "confirmed",
          description: "Pulse Secure Pulse Connect Secure (PCS) 8.2 before 8.2R12.1, 8.3 before 8.3R7.1, and 9.0 before 9.0R3.4, an unauthenticated remote attacker can send a specially crafted URI to perform an arbitrary file reading vulnerability.",
          affected_software: [ 
            { :vendor => "Juniper Networks\, Inc.", :product => "Pulse Secure" }
          ],
          references: [
            { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2019-11510" }
          ],
          authors: ["shpendk"]
        }.merge!(instance_details)
        end
      end
    end
  
    module Task
      class PulseSecureCve201911510 < BaseCheck 
      def self.check_metadata
        {
          allowed_types: ["Uri"]
        }
      end
  
      def check

        # run a nuclei 
        uri = _get_entity_name
        template = "vulnerabilities/moodle-filter-jmol-lfi"
        
        run_nuclei_template
      end
  
      end
    end
  
  end