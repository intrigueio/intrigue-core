
module Intrigue

  module Issue
    class VRealizeOperationsCve202121975 < BaseIssue
      def self.generate(instance_details={})
      {
        added: "2021-03-30",
        name: "vmware_vrealize_operations_manager_cve_2021_21975",
        pretty_name: "VMWare vRealize Operations Manager API SSRF (CVE-2021-21975)",
        severity: 1,
        category: "vulnerability",
        status: "confirmed",
        description: "Server Side Request Forgery in vRealize Operations Manager API (CVE-2021-21975) prior to 8.4 may allow a malicious actor with network access to the vRealize Operations Manager API can perform a Server Side Request Forgery attack to steal administrative credentials.",
        affected_software: [ 
          { :vendor => "VMware", :product => "vRealize Operations Manager" }
        ],
        references: [
          { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2021-21975" }
        ],
        authors: ["maxim"]
      }.merge!(instance_details)
      end
    end
  end

  module Task
    class VRealizeOperationsCve202121975 < BaseCheck
      def self.check_metadata
        {
          allowed_types: ['Uri']
        }
      end

      # return truthy value to create an issue
      def check

        # run a nuclei
        uri = _get_entity_name
        template = 'cves/2021/CVE-2021-21975'

        # if this returns truthy value, an issue will be raised
        # the truthy value will be added as proof to the issue
        run_nuclei_template uri, template
      end

    end
  end
end
