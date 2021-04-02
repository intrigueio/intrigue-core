
module Intrigue

  module Issue
    class ColdfusionCve202121087 < BaseIssue
      def self.generate(instance_details={})
      {
        added: "2021-03-30",
        name: "coldfusion_cve_2021_21087",
        pretty_name: "Adobe Coldfusion Arbitrary Code Execution (CVE-2021-21087)",
        severity: 1,
        category: "vulnerability",
        status: "confirmed",
        description: "The vulnerability exists due to insufficient validation of user-supplied input. A remote non-authenticated attacker can send specially crafted data to the application and execute arbitrary code on the system.",
        affected_software: [ 
          { :vendor => "Adobe", :product => "Coldfusion" }
        ],
        references: [
          { type: "description", uri: "https://helpx.adobe.com/security/products/coldfusion/apsb21-16.html" }
        ],
        authors: ["Josh Lane", "Daviey", "maxim"]
      }.merge!(instance_details)
      end
    end
  end

  module Task
    class ColdfusionCve202121087 < BaseCheck
      def self.check_metadata
        {
          allowed_types: ['Uri']
        }
      end

      # return truthy value to create an issue
      def check

        # run a nuclei
        uri = _get_entity_name
        template = 'miscellaneous/unpatched-coldfusion'

        # if this returns truthy value, an issue will be raised
        # the truthy value will be added as proof to the issue
        run_nuclei_template uri, template
      end

    end
  end
end
