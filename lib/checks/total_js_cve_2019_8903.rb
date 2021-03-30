
module Intrigue

    module Issue
      class TotalJSCve20198903 < BaseIssue
        def self.generate(instance_details={})
        {
          added: "2021-03-30",
          name: "total_js_cve_2019_8903 ",
          pretty_name: "Total.js path traversal vulnerability with CVE-2019-8903.",
          severity: 1,
          category: "vulnerability",
          status: "confirmed",
          description: "index.js in Total.js Platform before 3.2.3 allows path traversal.",
          affected_software: [ 
            { :vendor => "Total.js", :product => "Total.js Platform" }
          ],
          references: [
            { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2019-8903" }
          ],
          authors: ["jen140"]
        }.merge!(instance_details)
        end
      end
    end
  
    module Task
      class TotalJSCve20198903 < BaseCheck 
      def self.check_metadata
        {
          allowed_types: ["Uri"]
        }
      end
  
      # return truthy value to create an issue
      def check
        
        # run a nuclei 
        uri = _get_entity_name
        template = "cves/2019/CVE-2019-8903"
        
        # if this returns truthy value, an issue will be raised
        # the truthy value will be added as proof to the issue
        run_nuclei_template uri, template
      end
  
      end
    end
    
    end
