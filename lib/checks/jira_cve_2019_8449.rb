
module Intrigue

    module Issue
      class JiraCve20198449 < BaseIssue
        def self.generate(instance_details={})
        {
          added: "2021-03-30",
          name: "jira_cve_2019_8449",
          pretty_name: "Jira Username Enumeration (CVE-2019-8449)",
          severity: 3,
          category: "vulnerability",
          status: "confirmed",
          description: "The /rest/api/latest/groupuserpicker resource in Jira before version 8.4.0 allows remote attackers to enumerate usernames via an information disclosure vulnerability.",
          affected_software: [ 
            { :vendor => "Atlassian", :product => "Jira Software" }
          ],
          references: [
            { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2019-8449" },
            { type: "exploit", uri: "https://packetstormsecurity.com/files/156172/Jira-8.3.4-Information-Disclosure.html" }
          ],
          authors: ["Harsh Bothra", "Mufeed VH" ,"jen140"]
        }.merge!(instance_details)
        end
      end
    end
  
    module Task
      class JiraCve20198449 < BaseCheck 
      def self.check_metadata
        {
          allowed_types: ["Uri"]
        }
      end
  
      # return truthy value to create an issue
      def check
        
        # run a nuclei 
        uri = _get_entity_name
        template = "cves/2019/CVE-2019-8449"
        
        # if this returns truthy value, an issue will be raised
        # the truthy value will be added as proof to the issue
        run_nuclei_template uri, template
      end
  
      end
    end
    
    end
