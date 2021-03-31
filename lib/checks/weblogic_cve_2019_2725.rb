
module Intrigue

  module Issue
    class WebLogicCve20192725 < BaseIssue
      def self.generate(instance_details={})
      {
        added: "2021-03-30",
        name: "oracle_weblogic_rce_cve_2019_2725",
        pretty_name: "Oracle WebLogic Server RCE (CVE-2019-2725)",
        severity: 1,
        category: "vulnerability",
        status: "confirmed",
        description: " Oracle WebLogic Server component of Oracle Fusion Middleware (subcomponent: Web Services). Supported versions that are affected are 10.3.6.0.0 and 12.1.3.0.0. Easily exploitable vulnerability allows unauthenticated attacker with network access via HTTP to compromise Oracle WebLogic Server. Successful attacks of this vulnerability can result in takeover of Oracle WebLogic Server.",
        affected_software: [ 
          { :vendor => "Oracle", :product => "Weblogic Server" }
        ],
        references: [
          { type: "description", uri: "https://nvd.nist.gov/vuln/detail/cve-2019-2725" }
        ],
        authors: ["maxim"]
      }.merge!(instance_details)
      end
    end
  end

  module Task
    class WebLogicCve20192725 < BaseCheck
      def self.check_metadata
        {
          allowed_types: ['Uri']
        }
      end

      # return truthy value to create an issue
      def check

        # run a nuclei
        uri = _get_entity_name
        template = 'cves/2019/CVE-2019-2725'

        # if this returns truthy value, an issue will be raised
        # the truthy value will be added as proof to the issue
        run_nuclei_template uri, template
      end

    end
  end
end
