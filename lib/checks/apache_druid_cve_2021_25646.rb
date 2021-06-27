
module Intrigue

  module Issue
    class ApacheDruidCve202125646 < BaseIssue
      def self.generate(instance_details={})
      {
        added: "2021-03-30",
        name: "apache_druid_cve_2021_25646",
        pretty_name: "Apache Druid Remote Code Execution (CVE-2021-25646)",
        severity: 1,
        category: "vulnerability",
        status: "confirmed",
        description: "Apache Druid includes the ability to execute user-provided JavaScript code embedded in various types of requests. This functionality is intended for use in high-trust environments, and is disabled by default. However, in Druid 0.20.0 and earlier, it is possible for an authenticated user to send a specially-crafted request that forces Druid to run user-provided JavaScript code for that request, regardless of server configuration. This can be leveraged to execute code on the target machine with the privileges of the Druid server process.",
        identifiers: [
          { type: "CVE", name: "CVE-2021-25646" }
        ],
        affected_software: [ 
          { :vendor => "Apache", :product => "Druid" }
        ],
        references: [
          { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2021-25646" },
          { type: "description", uri: "https://blogs.juniper.net/en-us/threat-research/cve-2021-25646-apache-druid-embedded-javascript-remote-code-execution" },
          { type: "exploit", uri: "https://github.com/lp008/CVE-2021-25646" }
        ],
        authors: ["Litch1", "pikpikcu", "maxim"]
      }.merge!(instance_details)
      end
    end
  end

  module Task
    class ApacheDruidCve202125646 < BaseCheck
      def self.check_metadata
        {
          allowed_types: ['Uri']
        }
      end

      # return truthy value to create an issue
      def check

        # run a nuclei
        uri = _get_entity_name
        template = 'cves/2021/CVE-2021-25646'

        # if this returns truthy value, an issue will be raised
        # the truthy value will be added as proof to the issue
        run_nuclei_template uri, template
      end

    end
  end
end
