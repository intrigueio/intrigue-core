module Intrigue
  module Issue
    class CitrixShareFileCve20208982 < BaseIssue
      def self.generate(instance_details = {})
      {
        added: "2021-03-31",
        name: "citrix_sharefile_cve_2020_8982",
        pretty_name: "Citrix ShareFile StorageZones Unauthenticated Arbitrary File Read Vulnerability (CVE-2020-8982)",
        identifiers: [
          { type: "CVE", name: "CVE-2020-8982" }
        ],
        severity: 1,
        category: "vulnerability",
        status: "confirmed",
        description: "Citrix ShareFile StorageZones Controller versions up to 5.5.0 are vulnerable to an arbitrary " +
                      "file read attack. Successful exploitation of this vulnerability results in unauthorized access to all files " +
                      "hosted by ShareFile and potentially remote code execution.",
        affected_software: [
          { vendor: "Citrix", product: "ShareFile" },
        ],
        references: [
          { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2020-8982" },
          { type: "description", uri: "https://support.citrix.com/article/CTX269106" }
        ],
        authors: ["dwisiswant0", "shpendk"]
      }.merge!(instance_details)
      end
    end
  end

  module Task
    class CitrixShareFileCve20208982 < BaseCheck
      def self.check_metadata
        {
          allowed_types: ["Uri"]
        }
      end

      # return truthy value to create an issue
      def check
        # run a nuclei 
        uri = _get_entity_name
        template = "cves/2020/CVE-2020-8982"

        # if this returns truthy value, an issue will be raised
        # the truthy value will be added as proof to the issue
        run_nuclei_template uri, template
      end
    end
  end
end