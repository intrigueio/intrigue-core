
module Intrigue

  module Issue
    class GrafanaCve201915043 < BaseIssue
      def self.generate(instance_details={})
      {
        added: "2021-03-30",
        name: "grafana_cve_2019_15043",
        pretty_name: "Grafana Unauthenticated API (CVE-2019-15043)",
        severity: 2,
        category: "vulnerability",
        status: "confirmed",
        description: "In Grafana 2.x through 6.x before 6.3.4, parts of the HTTP API allow unauthenticated use. This makes it possible to run a denial of service attack against the server running Grafana.",
        affected_software: [ 
          { :vendor => "Grafana", :product => "Grafana" }
        ],
        references: [
          { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2019-15043" }
        ],
        authors: ["Jean-Louis Dupond", "bing0o", "maxim"]
      }.merge!(instance_details)
      end
    end
  end

  module Task
    class GrafanaCve201915043 < BaseCheck
      def self.check_metadata
        {
          allowed_types: ['Uri']
        }
      end

      # return truthy value to create an issue
      def check

        # run a nuclei
        uri = _get_entity_name
        template = 'cves/2019/CVE-2019-15043'

        # if this returns truthy value, an issue will be raised
        # the truthy value will be added as proof to the issue
        run_nuclei_template uri, template
      end

    end
  end
end
