module Intrigue
  module Issue
    class ApacheAirflowCve202017526 < BaseIssue
      def self.generate(instance_details = {})
        {
          added: "2021-06-30",
          name: "apache_airflow_cve_2020_17526",
          pretty_name: "Apache Airflow Webserver < 1.10.14 - Incorrect Session Validation (CVE-2020-17526)",
          identifiers: [
            { type: "CVE", name: "CVE-2020-17526" }
          ],
          severity: 2,
          category: "vulnerability",
          status: "potential",
          description: "Incorrect Session Validation in Apache Airflow Webserver versions prior to 1.10.14 with default config allows a malicious airflow user on site A where they log in normally, to access unauthorized Airflow Webserver on Site B through the session from Site A. This does not affect users who have changed the default value for `[webserver] secret_key` config.",
          affected_software: [
            { vendor: "Apache", product: "Airflow" }
          ],
          references: [
            { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2020-17526" },
            { type: "description", uri: "https://ian.sh/airflow" }
          ],
          authors: ["adambakalar", "iangcarroll"]
        }.merge!(instance_details)
      end
    end
  end

  module Task
    class ApacheAirflowCve202017526 < BaseCheck
      def self.check_metadata
        {
          allowed_types: ["Uri"]
        }
      end

      # return truthy value to create an issue

      def check

        # first, ensure we're fingerprinted
        require_enrichment

        # get version for product
        version = get_version_for_vendor_product(@entity, "Apache", "Airflow")
        return false unless version
       
        # compare the version we got to the vulnerable version
        is_vulnerable = compare_versions_by_operator(version, "1.10.14" , "<")

        return is_vulnerable
      end
    end
  end
end
