
module Intrigue

  module Issue
    class AtlassianCve20193396 < BaseIssue
      def self.generate(instance_details={})
      {
        added: "2021-03-30",
        name: "atlassian_confluence_cve_2019_3396",
        pretty_name: "Atlassian Confluence Server Path Traversal (CVE-2019-3396)",
        severity: 1,
        category: "vulnerability",
        status: "confirmed",
        description: "The Widget Connector macro in Atlassian Confluence Server before version 6.6.12 (the fixed version for 6.6.x), from version 6.7.0 before 6.12.3 (the fixed version for 6.12.x), from version 6.13.0 before 6.13.3 (the fixed version for 6.13.x), and from version 6.14.0 before 6.14.2 (the fixed version for 6.14.x), allows remote attackers to achieve path traversal and remote code execution on a Confluence Server or Data Center instance via server-side template injection.",
        affected_software: [ 
          { :vendor => "Atlassian", :product => "Confluence" }
        ],
        references: [
          { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2019-3396" }
        ],
        authors: ["maxim"]
      }.merge!(instance_details)
      end
    end
  end

  module Task
    class AtlassianCve20193396 < BaseCheck
      def self.check_metadata
        {
          allowed_types: ['Uri']
        }
      end

      # return truthy value to create an issue
      def check

        # run a nuclei
        uri = _get_entity_name
        template = 'cves/2019/CVE-2019-3396'

        # if this returns truthy value, an issue will be raised
        # the truthy value will be added as proof to the issue
        run_nuclei_template uri, template
      end

    end
  end
end
