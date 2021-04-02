module Intrigue
  module Issue
    class ApacheOfbizCve20188033 < BaseIssue
      def self.generate(instance_details = {})
      {
        added: "2021-04-02",
        name: "apache_ofbiz_cve_2018_8033",
        pretty_name: "Apache OFBiz XML External Entity Vulnerability (CVE-2018-8033)",
        identifiers: [
          { type: "CVE", name: "CVE-2018-8033" }
        ],
        severity: 1,
        category: "vulnerability",
        status: "confirmed",
        description: 
          "Apache OFBiz versions 16.11.01 to 16.11.04 are vulnerable to XML External Entity attacks. " +
          "GET and POST requests to the httpService endpoint may contain DOCTYPEs pointing to external " +
          "references that trigger a payload which returns secret information from the host. " +
          "Successful exploitation of this vulnerability can result in access to sensitive files.",
        affected_software: [
          { vendor: "Apache", product: "Coyote" }
        ],
        references: [
          { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2018-8033" },
          { type: "description", uri: "https://lists.apache.org/thread.html/e8fb551e86e901932081f81ee9985bb72052b4d412f23d89b1282777@%3Cuser.ofbiz.apache.org%3E" },
          { type: "exploit", uri: "https://github.com/jamieparfet/Apache-OFBiz-XXE" }
        ],
        authors: ["jamieparfet", "pikpikcu", "shpendk"]
      }.merge!(instance_details)
      end
    end
  end

  module Task
    class ApacheOfbizCve20188033 < BaseCheck
      def self.check_metadata
        {
          allowed_types: ["Uri"]
        }
      end

      # return truthy value to create an issue
      def check
        # run a nuclei 
        uri = _get_entity_name
        template = "cves/2018/CVE-2018-8033"

        # if this returns truthy value, an issue will be raised
        # the truthy value will be added as proof to the issue
        run_nuclei_template uri, template
      end
    end
  end
end