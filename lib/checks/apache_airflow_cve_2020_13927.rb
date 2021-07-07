module Intrigue
  module Issue
    class ApacheAirflowCve202013927 < BaseIssue
      def self.generate(instance_details = {})
        {
          added: "2021-06-30",
          name: "apache_airflow_cve_2020_13927",
          pretty_name: "Apache Airflow Unauthenticated Access to Experimental REST API (CVE-2020-13927)",
          severity: 1,
          category: "vulnerability",
          status: "confirmed",
          description: "The previous default setting for Airflow's Experimental API was to allow all API requests without authentication, but this poses security risks to users who miss this fact.",
          identifiers: [
            { type: "CVE", name: "CVE-2020-13927" }
          ],
          affected_software: [
            { vendor: "Apache", product: "Airflow" }
          ],
          references: [
            { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2020-13927" }
          ],
          authors: ["pdteam", "adambakalar"]
        }.merge!(instance_details)
      end
    end
  end

  module Task
    class ApacheAirflowCve202013927 < BaseCheck
      def self.check_metadata
        {
          allowed_types: ["Uri"]
        }
      end

      # return truthy value to create an issue
      def check
        # run a nuclei
        uri = _get_entity_name
        template = "cves/2020/CVE-2020-13927"

        # if this returns truthy value, an issue will be raised
        # the truthy value will be added as proof to the issue
        run_nuclei_template uri, template
      end
    end
  end
end
