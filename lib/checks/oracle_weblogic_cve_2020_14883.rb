module Intrigue
  module Issue
    class OracleWeblogicCve202014883 < BaseIssue
      def self.generate(instance_details = {})
      {
        added: "2021-04-02",
        name: "oracle_weblogic_cve_2020_14883",
        pretty_name: "Oracle WebLogic Server Administration Console Handle Remote Code Execution (CVE-2020-14883)",
        identifiers: [
          { type: "CVE", name: "CVE-2020-14883" }
        ],
        severity: 2,
        category: "vulnerability",
        status: "confirmed",
        description: 
          "Oracle Weblogic versions 10.3.6.0.0, 12.1.3.0.0, 12.2.1.3.0, 12.2.1.4.0 and 14.1.1.0.0 are vulnerable to a " +
          "remote code execution vulnerability. A high privileged attacker with network access via HTTP " +
          "can execute arbitrary commands which may lead to total takeover of the underlying server. ",
        affected_software: [
          { vendor: "Oracle", product: "Weblogic" },
          { vendor: "Oracle", product: "Weblogic Server" }
        ],
        references: [
          { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2020-14883" },
          { type: "description", uri: "https://www.oracle.com/security-alerts/cpuoct2020.html" },
          { type: "exploit", uri: "https://github.com/murataydemir/CVE-2020-14883" }
        ],
        authors: ["murataydemir", "pdteam", "shpendk"]
      }.merge!(instance_details)
      end
    end
  end

  module Task
    class OracleWeblogicCve202014883 < BaseCheck
      def self.check_metadata
        {
          allowed_types: ["Uri"]
        }
      end

      # return truthy value to create an issue
      def check
        # run a nuclei 
        uri = _get_entity_name
        template = "cves/2020/CVE-2020-14883"

        # if this returns truthy value, an issue will be raised
        # the truthy value will be added as proof to the issue
        run_nuclei_template uri, template
      end
    end
  end
end