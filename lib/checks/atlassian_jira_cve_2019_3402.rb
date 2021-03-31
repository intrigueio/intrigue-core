
module Intrigue

  module Issue
    class AtlassianCve20193402 < BaseIssue
      def self.generate(instance_details={})
      {
        added: "2021-03-30",
        name: "atlassian_jira_cve_2019_3402",
        pretty_name: "Atlassian Jira Reflected XSS (CVE-2019-3402)",
        severity: 3,
        category: "vulnerability",
        status: "confirmed",
        description: "The ConfigurePortalPages.jspa resource in Jira before version 7.13.3 and from version 8.0.0 before version 8.1.1 allows remote attackers to inject arbitrary HTML or JavaScript via a cross site scripting (XSS) vulnerability in the searchOwnerUserName parameter.",
        affected_software: [ 
          { :vendor => "Atlassian", :product => "Jira" }
        ],
        references: [
          { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2019-3402" }
        ],
        authors: ["maxim"]
      }.merge!(instance_details)
      end
    end
  end

  module Task
    class AtlassianCve20193402 < BaseCheck
      def self.check_metadata
        {
          allowed_types: ['Uri']
        }
      end

      # return truthy value to create an issue
      def check

        # run a nuclei
        uri = _get_entity_name
        template = 'cves/2019/CVE-2019-3402'

        # if this returns truthy value, an issue will be raised
        # the truthy value will be added as proof to the issue
        run_nuclei_template uri, template
      end

    end
  end
end
