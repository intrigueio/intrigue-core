
module Intrigue

  module Issue
    class FortiwebCve202122122 < BaseIssue
      def self.generate(instance_details={})
      {
        added: "2021-03-30",
        name: "fortiweb_cve_2021_21975",
        pretty_name: "FortiWeb Reflected XSS (CVE-2021-21975)",
        severity: 3,
        category: "vulnerability",
        status: "confirmed",
        description: "An improper neutralization of input during web page generation in FortiWeb GUI interface 6.3.0 through 6.3.7 and version before 6.2.4 may allow an unauthenticated, remote attacker to perform a reflected cross site scripting attack (XSS) by injecting malicious payload in different vulnerable API end-points.",
        affected_software: [ 
          { :vendor => "Fortinet", :product => "FortiWeb" }
        ],
        references: [
          { type: "description", uri: "https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-22122" }
        ],
        authors: ["maxim"]
      }.merge!(instance_details)
      end
    end
  end

  module Task
    class FortiwebCve202122122 < BaseCheck
      def self.check_metadata
        {
          allowed_types: ['Uri']
        }
      end

      # return truthy value to create an issue
      def check

        # run a nuclei
        uri = _get_entity_name
        template = 'cves/2021/CVE-2021-22122'

        # if this returns truthy value, an issue will be raised
        # the truthy value will be added as proof to the issue
        run_nuclei_template uri, template
      end

    end
  end
end
