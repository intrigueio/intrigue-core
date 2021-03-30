
module Intrigue

    module Issue
      class SpringCloudConfigCve20193799 < BaseIssue
        def self.generate(instance_details={})
        {
          added: "2020-11-19",
          name: "spring_cloud_config_cve_2019_3799",
          pretty_name: "Spring Cloud Config Server Directory Traversal Vulnerability (CVE-2919-3799)",
          identifiers: [
            { type: "CVE", name: "CVE-2919-3799" }
          ],
          severity: 1,
          category: "vulnerability",
          status: "confirmed",
          description: "Spring Cloud Config, versions 2.1.x prior to 2.1.2, versions 2.0.x prior to 2.0.4, and versions 1.4.x prior to 1.4.6, and older unsupported versions allow applications to serve arbitrary configuration files through the spring-cloud-config-server module. A malicious user, or attacker, can send a request using a specially crafted URL that can lead a directory traversal attack.",
          affected_software: [],
          references: [
            { type: "description", uri: "https://spring.io/blog/2019/04/17/cve-2019-3799-spring-cloud-config-2-1-2-2-0-4-1-4-6-released" },
            { type: "description", uri: "https://tanzu.vmware.com/security/cve-2019-3799" },
            { type: "exploit", uri: "https://github.com/mpgn/CVE-2019-3799" },
          ],
          authors: ["mpgn", "madrobot", "shpendk"]
        }.merge!(instance_details)
        end
      end
    end
  
    module Task
      class SpringCloudConfigCve20193799 < BaseCheck 
        def self.check_metadata
          {
            allowed_types: ["Uri"]
          }
        end
  
        # return truthy value to create an issue
        def check
          # run a nuclei 
          uri = _get_entity_name
          template = "cves/2019/CVE-2019-3799"

          # if this returns truthy value, an issue will be raised
          # the truthy value will be added as proof to the issue
          run_nuclei_template uri, template
        end
  
      end
    end
    
end