module Intrigue
  module Issue
    class OracleWeblogicCve20192725 < BaseIssue
      def self.generate(instance_details = {})
      {
        added: "2021-04-02",
        name: "oracle_weblogic_cve_2019_2725",
        pretty_name: "Oracle Weblogic Unauthenticated Remote Code Execution (CVE-2019-2725)",
        identifiers: [
          { type: "CVE", name: "CVE-2019-2725" }
        ],
        severity: 1,
        category: "vulnerability",
        status: "confirmed",
        description: 
          "Oracle Weblogic versions 10.3.6.0.0 and 12.1.3.0.0 are vulnerable to a remote code execution vulnerability. " +
          "Unauthenticated attackers with network access via HTTP can easily exploit this vulnerability to compromise " +
          "Oracle Weblogic Servers. Successful exploitation can result in total takeover of the underlying server. ",
        affected_software: [
          { vendor: "Oracle", product: "Weblogic" },
          { vendor: "Oracle", product: "Weblogic Server" }
        ],
        references: [
          { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2019-2725" },
          { type: "description", uri: "https://www.oracle.com/security-alerts/alert-cve-2019-2725.html" },
          { type: "exploit", uri: "https://github.com/lasensio/cve-2019-2725" }
        ],
        authors: ["lasensio", "dwisiswant0", "shpendk"]
      }.merge!(instance_details)
      end
    end
  end

  module Task
    class OracleWeblogicCve20192725 < BaseCheck
      def self.check_metadata
        {
          allowed_types: ["Uri"]
        }
      end

      # return truthy value to create an issue
      def check
        # run a nuclei 
        uri = _get_entity_name
        template = "cves/2019/CVE-2019-2725"

        # if this returns truthy value, an issue will be raised
        # the truthy value will be added as proof to the issue
        run_nuclei_template uri, template
      end
    end
  end
end