
module Intrigue

    module Issue
      class W3TotalCacheCve20196715 < BaseIssue
        def self.generate(instance_details={})
        {
          added: "2021-03-30",
          name: "w3_total_cache_cve_2019_6715 ",
          pretty_name: "W3 Total Cache Wordpress Plugin Arbitrary file read with CVE-2019-6715.",
          severity: 1,
          category: "vulnerability",
          status: "confirmed",
          description: "pub/sns.php in the W3 Total Cache plugin before 0.9.4 for WordPress allows remote attackers to read arbitrary files via the SubscribeURL field in SubscriptionConfirmation JSON data.",
          affected_software: [ 
            { :vendor => "BoldGrid", :product => "W3 Total Cache" }
          ],
          references: [
            { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2019-6715" },
            { type: "POC", uri: "https://packetstormsecurity.com/files/160674/WordPress-W3-Total-Cache-0.9.3-File-Read-Directory-Traversal.html" }
          ],
          authors: ["jen140"]
        }.merge!(instance_details)
        end
      end
    end
  
    module Task
      class W3TotalCacheCve20196715 < BaseCheck 
      def self.check_metadata
        {
          allowed_types: ["Uri"]
        }
      end
  
      # return truthy value to create an issue
      def check
        
        # run a nuclei 
        uri = _get_entity_name
        template = "cves/2019/CVE-2019-6715"
        
        # if this returns truthy value, an issue will be raised
        # the truthy value will be added as proof to the issue
        run_nuclei_template uri, template
      end
  
      end
    end
    
    end
