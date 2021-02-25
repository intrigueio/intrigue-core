
module Intrigue

    module Issue
      class VmwareCve202121972 < BaseIssue
        def self.generate(instance_details={})
        {
          added: "2021-02-25",
          name: "vmware_cve_2021_21972",
          pretty_name: "Vmware RCE CVE-2021-21972",
          severity: 1,
          category: "vulnerability",
          status: "confirmed",
          description: "Vmware ESXi, vCenter Server and Cloud Foundation are vulnerable to an unauthenticated remote code execution. A malicious actor with network access to port 443 may exploit this issue to execute commands with unrestricted privileges on the underlying operating system.",
          affected_software: [ 
            { :vendor => "VMware", :product => "VMware" },
            { :vendor => "VMware", :product => "VCLOUD" },
            { :vendor => "VMware", :product => "ESXi" }
          ],
          remediation: "Check Vmware's description and update to the latest version.",
          references: [
            { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2021-21972" },
            { type: "description", uri: "https://www.vmware.com/security/advisories/VMSA-2021-0002.html" },
            { type: "exploit", uri: "https://attackerkb.com/topics/lrfxAJ9nhV/vmware-vsphere-client-unauth-remote-code-execution-vulnerability-cve-2021-21972?referrer=notificationEmail#rapid7-analysis" },
          ],
          authors: ["Mikhail Klyuchnikov", "shpendk"]
        }.merge!(instance_details)
        end
      end
    end
  
    module Task
      class VmwareCve202121972 < BaseCheck 
      def self.check_metadata
        {
          allowed_types: ["Uri"]
        }
      end
  
      # return truthy value to create an issue
      def check
        # get enriched entity
        require_enrichment
        uri = _get_entity_name

        # check if vuln
        response = http_request :get, uri
        if  response.code.to_i == 200 && response.body_utf8 =~ /(Install|Config) Final Progress/
            _log "Vulnerable!"
            return response.body_utf8
        end

        # if original URI didn't work, lets try the default url
        _log "Testing at /ui/vropspluginui/rest/services/getstatus"
        uri_obj = URI(uri)
        endpoint = "#{uri_obj.scheme}://#{uri_obj.hostname}:#{uri_obj.port}/ui/vropspluginui/rest/services/getstatus"
        response = http_request :get, endpoint
        if  response.code.to_i == 200 && response.body_utf8 =~ /(Install|Config) Final Progress/
            _log "Vulnerable!"
            return response.body_utf8
        end

      end
  
      end
    end
    
end # module end