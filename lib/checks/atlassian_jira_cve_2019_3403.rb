
module Intrigue

  module Issue
    class AtlassianCve20193403 < BaseIssue
      def self.generate(instance_details={})
      {
        added: "2021-03-30",
        name: "atlassian_jira_cve_2019_3403",
        pretty_name: "Atlassian Jira User Enumeration (CVE-2019-3403)",
        severity: 4,
        category: "vulnerability",
        status: "confirmed",
        description: "The /rest/api/2/user/picker rest resource in Jira before version 7.13.3, from version 8.0.0 before version 8.0.4, and from version 8.1.0 before version 8.1.1 allows remote attackers to enumerate usernames via an incorrect authorisation check.",
        identifiers: [
          { type: "CVE", name: "CVE-2019-3403" }
        ],
        affected_software: [ 
          { :vendor => "Atlassian", :product => "Jira" }
        ],
        references: [
          { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2019-3403" },
          { type: "description", uri: "https://jira.atlassian.com/browse/JRASERVER-69242" }
        ],
        authors: ["Ganofins", "maxim"]
      }.merge!(instance_details)
      end
    end
  end

  module Task
    class AtlassianCve20193403 < BaseCheck
      def self.check_metadata
        {
          allowed_types: ['Uri']
        }
      end

      # return truthy value to create an issue
      def check

        # run a nuclei
        uri = _get_entity_name
        template = 'cves/2019/CVE-2019-3403'

        # if this returns truthy value, an issue will be raised
        # the truthy value will be added as proof to the issue
        run_nuclei_template uri, template
      end

    end
  end
end
