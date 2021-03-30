
module Intrigue

    module Issue
      class JfrogArtifactoryCve20199733 < BaseIssue
        def self.generate(instance_details={})
        {
          added: "2021-03-30",
          name: "jfrog_artifactory_cve_2019_9733",
          pretty_name: "Jfrog Artifactory unauthenticated admin password reset CVE-2019-9733",
          severity: 1,
          category: "vulnerability",
          status: "confirmed",
          description: "An issue was discovered in JFrog Artifactory 6.7.3. By default, the access-admin account is used to reset the password of the admin account in case an administrator gets locked out from the Artifactory console. This is only allowable from a connection directly from localhost, but providing a X-Forwarded-For HTTP header to the request allows an unauthenticated user to login with the default credentials of the access-admin account while bypassing the whitelist of allowed IP addresses. The access-admin account can use Artifactory's API to request authentication tokens for all users including the admin account and, in turn, assume full control of all artifacts and repositories managed by Artifactory.",
          affected_software: [ 
            { :vendor => "Jfrog", :product => "Artifactory" }
          ],
          references: [
            { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2019-9733" },
            { type: "POC", uri: "https://packetstormsecurity.com/files/152172/JFrog-Artifactory-Administrator-Authentication-Bypass.html" }
          ],
          authors: ["jen140"]
        }.merge!(instance_details)
        end
      end
    end
  
    module Task
      class JfrogArtifactoryCve20199733 < BaseCheck 
      def self.check_metadata
        {
          allowed_types: ["Uri"]
        }
      end
  
      # return truthy value to create an issue
      def check
        
        # run a nuclei 
        uri = _get_entity_name
        template = "cves/2019/CVE-2019-9733"
        
        # if this returns truthy value, an issue will be raised
        # the truthy value will be added as proof to the issue
        run_nuclei_template uri, template
      end
  
      end
    end
    
    end
