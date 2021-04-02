module Intrigue
  module Issue
    class OracleBusinessIntelligenceCve202014864 < BaseIssue
      def self.generate(instance_details = {})
      {
        added: "2021-04-02",
        name: "oracle_business_intelligence_cve_2020_14864",
        pretty_name: "Oracle Business Intelligence Directory Traversal Vulnerability (CVE-2020-14864)",
        identifiers: [
          { type: "CVE", name: "CVE-2020-14864" }
        ],
        severity: 1,
        category: "vulnerability",
        status: "confirmed",
        description:
          "The Oracle Business Intelligence Enterprise Edition product of Oracle Fusion Middleware (component: Installation) " +
          "is vulnerable to a directory traversal vulnerability. An unauthenticated attacker with network access via HTTP " +
          "can exploit this vulnerability to obtain access to all Oracle Business Intelligence Enterprise Edition accessible data.",
        affected_software: [
          { vendor: "Oracle", product: "Fusion Middleware" },
          { vendor: "Oracle", product: "Application Server" }
        ],
        references: [
          { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2020-14864" },
          { type: "exploit", uri: "https://www.exploit-db.com/exploits/48964" }
        ],
        authors: ["@palaziv", "shpendk"]
      }.merge!(instance_details)
      end
    end
  end

  module Task
    class OracleBusinessIntelligenceCve202014864 < BaseCheck
      def self.check_metadata
        {
          allowed_types: ["Uri"]
        }
      end

      # return truthy value to create an issue
      def check
        # run a nuclei 
        uri = _get_entity_name
        template = "cves/2020/CVE-2020-14864"

        # if this returns truthy value, an issue will be raised
        # the truthy value will be added as proof to the issue
        run_nuclei_template uri, template
      end
    end
  end
end