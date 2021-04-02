module Intrigue
  module Issue
    class ApacheOfbizCve202126295 < BaseIssue
      def self.generate(instance_details = {})
      {
        added: "2021-04-01",
        name: "apache_ofbiz_cve_2021_26295",
        pretty_name: "Apache OFBiz RMI Unsafe Deserialization (CVE-2021-26295)",
        identifiers: [
          { type: "CVE", name: "CVE-2021-26295" }
        ],
        severity: 1,
        category: "vulnerability",
        status: "confirmed",
        description: 
          "Apache OFBiz prior to 17.12.06 is vulnerable to an unsafe java deserialization vulnerability. " +
          "Successful exploitation of this vulnerability could lead to remote code execution.",
        affected_software: [
          { vendor: "Apache", product: "Coyote" }
        ],
        references: [
          { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2021-26295" },
          { type: "description", uri: "https://www.tenable.com/cve/CVE-2021-26295" },
          { type: "exploit", uri: "https://github.com/yumusb/CVE-2021-26295" }
        ],
        authors: ["yumusb", "madrobot", "shpendk"]
      }.merge!(instance_details)
      end
    end
  end

  module Task
    class ApacheOfbizCve202126295 < BaseCheck
      def self.check_metadata
        {
          allowed_types: ["Uri"]
        }
      end

      # return truthy value to create an issue
      def check
        # run a nuclei 
        uri = _get_entity_name
        template = "cves/2021/CVE-2021-26295"

        # if this returns truthy value, an issue will be raised
        # the truthy value will be added as proof to the issue
        run_nuclei_template uri, template
      end
    end
  end
end