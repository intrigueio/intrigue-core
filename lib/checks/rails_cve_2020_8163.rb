module Intrigue
  module Issue
    class RailsCve20208163 < BaseIssue
      def self.generate(instance_details = {})
      {
        added: "2021-03-31",
        name: "rails_cve_2020_8163",
        pretty_name: "Rails Remote Code Execution Vulnerability (CVE-2020-8163)",
        identifiers: [
          { type: "CVE", name: "CVE-2020-8163" }
        ],
        severity: 1,
        category: "vulnerability",
        status: "confirmed",
        description: "A remote code execution vulnerability exists in Rails versions prior to 5.0.1. " +
                      "If an attacker controls the input to the 'locals' argument while rendering a partial, " +
                      "he/she can inject code which can lead to remote code execution.",
        affected_software: [
          { vendor: "RubyOnRails", product: "Rails" },
        ],
        references: [
          { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2020-8163" },
          { type: "exploit", uri: "https://correkt.horse/ruby/2020/08/22/CVE-2020-8163/" }
        ],
        authors: ["tim_koopmans", "shpendk"]
      }.merge!(instance_details)
      end
    end
  end

  module Task
    class RailsCve20208163 < BaseCheck
      def self.check_metadata
        {
          allowed_types: ["Uri"]
        }
      end

      # return truthy value to create an issue
      def check
        # run a nuclei 
        uri = _get_entity_name
        template = "cves/2020/CVE-2020-8163"

        # if this returns truthy value, an issue will be raised
        # the truthy value will be added as proof to the issue
        run_nuclei_template uri, template
      end
    end
  end
end