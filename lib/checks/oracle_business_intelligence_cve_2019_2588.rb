module Intrigue
  module Issue
    class OracleBusinessIntelligenceCve20192588 < BaseIssue
      def self.generate(instance_details = {})
      {
        added: "2020-11-19",
        name: "oracle_business_intelligence_cve_2019_2588",
        pretty_name: "Oracle Business Intelligence Directory Traversal Vulnerability (CVE-2019-2588)",
        identifiers: [
          { type: "CVE", name: "CVE-2019-2588" }
        ],
        severity: 1,
        category: "vulnerability",
        status: "confirmed",
        description: "Oracle Business Intelligence versions 11.1.1.9.0, 12.2.1.3.0 and 12.2.1.4.0 are vulnerable to a directory " +
                      "traversal attack. Successful exploitation of this vulnerability can result in unauthorized access to critical " +
                      "data or complete access to the filesystem.",
        affected_software: [
          { vendor: "Oracle", product: "Fusion Middleware" },
          { vendor: "Oracle", product: "Application Server" }
        ],
        references: [
          { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2019-2588" },
          { type: "exploit", uri: "https://www.exploit-db.com/exploits/46728" }
        ],
        authors: ["@vah_13", "madrobot", "shpendk"]
      }.merge!(instance_details)
      end
    end
  end

  module Task
    class OracleBusinessIntelligenceCve20192588 < BaseCheck
      def self.check_metadata
        {
          allowed_types: ["Uri"]
        }
      end

      # return truthy value to create an issue
      def check
        # run a nuclei 
        uri = _get_entity_name
        template = "cves/2019/CVE-2019-2588"

        # if this returns truthy value, an issue will be raised
        # the truthy value will be added as proof to the issue
        run_nuclei_template uri, template
      end
    end
  end
end