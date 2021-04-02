module Intrigue
  module Issue
    class ApacheSolrCve201917558 < BaseIssue
      def self.generate(instance_details = {})
      {
        added: "2020-11-19",
        name: "apache_solr_cve_2019_17558",
        pretty_name: "Apache Solr Remote Code Execution Vulnerability (CVE-2019-17558)",
        identifiers: [
          { type: "CVE", name: "CVE-2019-17558" }
        ],
        severity: 1,
        category: "vulnerability",
        status: "confirmed",
        description: "Apache Solr 5.0.0 to Apache Solr 8.3.1 are vulnerable to a Remote Code Execution through the VelocityResponseWriter. " +
                     "By using a custom template via the velocity directory or as a parameter, remote code execution can be triggered. " +
                     "By default, parameterized templates are disabled. However, attackers can enable it via a specially crafted HTTP POST request to the Config API.",
        affected_software: [
          { vendor: "Apache", product: "Solr" }
        ],
        references: [
          { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2019-17558" },
          { type: "description", uri: "https://www.tenable.com/blog/cve-2019-17558-apache-solr-vulnerable-to-remote-code-execution-zero-day-vulnerability" },
          { type: "exploit", uri: "https://packetstormsecurity.com/files/157078/Apache-Solr-8.3.0-Velocity-Template-Remote-Code-Execution.html" }
        ],
        authors: ["s00py", "jas502n", "AleWong", "pikpikcu", "shpendk"]
      }.merge!(instance_details)
      end
    end
  end

  module Task
    class ApacheSolrCve201917558 < BaseCheck
      def self.check_metadata
        {
          allowed_types: ["Uri"]
        }
      end

      # return truthy value to create an issue
      def check
        # run a nuclei check
        uri = _get_entity_name
        template = "cves/2019/CVE-2019-17558"

        # if this returns truthy value, an issue will be raised
        # the truthy value will be added as proof to the issue
        run_nuclei_template uri, template
      end
    end
  end
end