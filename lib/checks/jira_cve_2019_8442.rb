
module Intrigue

    module Issue
      class JiraCve20198442 < BaseIssue
        def self.generate(instance_details={})
        {
          added: "2021-03-30",
          name: "jira_cve_2019_8442 ",
          pretty_name: "Jira Server META-INF directory exposure with CVE-2019-8442.",
          severity: 1,
          category: "vulnerability",
          status: "confirmed",
          description: "The CachingResourceDownloadRewriteRule class in Jira before version 7.13.4, and from version 8.0.0 before version 8.0.4, and from version 8.1.0 before version 8.1.1 allows remote attackers to access files in the Jira webroot under the META-INF directory via a lax path access check.",
          affected_software: [ 
            { :vendor => "Atlassian", :product => "Jira Software" }
          ],
          references: [
            { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2019-8442" }
          ],
          authors: ["jen140"]
        }.merge!(instance_details)
        end
      end
    end
  
    module Task
      class JiraCve20198442 < BaseCheck 
      def self.check_metadata
        {
          allowed_types: ["Uri"]
        }
      end
  
      # return truthy value to create an issue
      def check
        
        # run a nuclei 
        uri = _get_entity_name
        template = "cves/2019/CVE-2019-8442"
        
        # if this returns truthy value, an issue will be raised
        # the truthy value will be added as proof to the issue
        run_nuclei_template uri, template
      end
  
      end
    end
    
    end
