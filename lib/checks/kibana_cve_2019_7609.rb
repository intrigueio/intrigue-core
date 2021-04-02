
module Intrigue

    module Issue
      class KibanaCve20197609 < BaseIssue
        def self.generate(instance_details={})
        {
          added: "2021-03-30",
          name: "kibana_cve_2019_7609",
          pretty_name: "Kibana Remote Code Execution (CVE-2019-7609)",
          severity: 1,
          category: "vulnerability",
          status: "confirmed",
          description: "Kibana versions before 5.6.15 and 6.6.1 contain an arbitrary code execution flaw in the Timelion visualizer. An attacker with access to the Timelion application could send a request that will attempt to execute javascript code. This could possibly lead to an attacker executing arbitrary commands with permissions of the Kibana process on the host system.",
          affected_software: [ 
            { :vendor => "Elastic", :product => "Kibana" }
          ],
          references: [
            { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2019-7609" },
            { type: "description", uri: "https://discuss.elastic.co/t/elastic-stack-6-6-1-and-5-6-15-security-update/169077" }
          ],
          authors: ["dwisiswant0","jen140"]
        }.merge!(instance_details)
        end
      end
    end
  
    module Task
      class KibanaCve20197609 < BaseCheck 
      def self.check_metadata
        {
          allowed_types: ["Uri"]
        }
      end
  
      # return truthy value to create an issue
      def check
        
        # run a nuclei 
        uri = _get_entity_name
        template = "cves/2019/CVE-2019-7609"
        
        # if this returns truthy value, an issue will be raised
        # the truthy value will be added as proof to the issue
        run_nuclei_template uri, template
      end
  
      end
    end
    
    end