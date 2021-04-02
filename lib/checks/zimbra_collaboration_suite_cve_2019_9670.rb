
module Intrigue

    module Issue
      class ZimbraCollaborationSuiteCve20199670 < BaseIssue
        def self.generate(instance_details={})
        {
          added: "2021-03-30",
          name: "zimbra_collaboration_suite_cve_2019_9670",
          pretty_name: "Zimbra Collaboration Suite 8.7.x XML External Entity injection (CVE-2019-9670)",
          severity: 1,
          category: "vulnerability",
          status: "confirmed",
          description: "mailboxd component in Synacor Zimbra Collaboration Suite 8.7.x before 8.7.11p10 has an XML External Entity injection (XXE) vulnerability.",
          affected_software: [ 
            { :vendor => "Zimbra", :product => "Collaboration Suite" }
          ],
          references: [
            { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2019-9670" },
            { type: "exploit", uri: "https://packetstormsecurity.com/files/152487/Zimbra-Collaboration-Autodiscover-Servlet-XXE-ProxyServlet-SSRF.html" }
          ],
          authors: ["ree4pwn", "Jacob Robles", "jen140"]
        }.merge!(instance_details)
        end
      end
    end
  
    module Task
      class ZimbraCollaborationSuiteCve20199670 < BaseCheck 
      def self.check_metadata
        {
          allowed_types: ["Uri"]
        }
      end
  
      # return truthy value to create an issue
      def check
        
        # run a nuclei 
        uri = _get_entity_name
        template = "cves/2019/CVE-2019-9670"
        
        # if this returns truthy value, an issue will be raised
        # the truthy value will be added as proof to the issue
        run_nuclei_template uri, template
      end
  
      end
    end
    
    end