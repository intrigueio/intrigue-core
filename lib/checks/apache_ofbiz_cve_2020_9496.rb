module Intrigue
  module Issue
    class ApacheOfbizCve20209496 < BaseIssue
      def self.generate(instance_details = {})
      {
        added: "2021-04-01",
        name: "apache_ofbiz_cve_2020_9496",
        pretty_name: "Apache OFBiz XML-RPC Java Deserialization (CVE-2020-9496)",
        identifiers: [
          { type: "CVE", name: "CVE-2020-9496" }
        ],
        severity: 1,
        category: "vulnerability",
        status: "confirmed",
        description: 
        "Apache OFBiz is vulnerable to an unsafe java deserialization vulnerability. " +
        "An unauthenticated attacker could exploit this vulnerability by sending a specially crafted request. "+
        "Successful exploitation of this vulnerability could lead to remote code execution.",
        affected_software: [
          { vendor: "Apache", product: "Coyote" }
        ],
        references: [
          { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2020-9496" },
          { type: "description", uri: "https://www.zerodayinitiative.com/blog/2020/9/14/cve-2020-9496-rce-in-apache-ofbiz-xmlrpc-via-deserialization-of-untrusted-data" },
          { type: "exploit", uri: "https://packetstormsecurity.com/files/158887/Apache-OFBiz-XML-RPC-Java-Deserialization.html" }
        ],
        authors: ["Alvaro Munoz", "wvu", "dwisiswant0", "shpendk"]
      }.merge!(instance_details)
      end
    end
  end

  module Task
    class ApacheOfbizCve20209496 < BaseCheck
      def self.check_metadata
        {
          allowed_types: ["Uri"]
        }
      end

      # return truthy value to create an issue
      def check
        # run a nuclei 
        uri = _get_entity_name
        template = "cves/2020/CVE-2020-9496"

        # if this returns truthy value, an issue will be raised
        # the truthy value will be added as proof to the issue
        run_nuclei_template uri, template
      end
    end
  end
end