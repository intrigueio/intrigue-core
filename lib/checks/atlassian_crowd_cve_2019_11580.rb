module Intrigue
  module Issue
    class AtlassianCrowdCve201911580 < BaseIssue
      def self.generate(instance_details = {})
      {
        added: "2020-11-19",
        name: "atlassian_crowd_cve_2019_11580",
        pretty_name: "Atlassian Crowd and Crowd Data Center Remote Code Execution Vulnerability (CVE-2019-11580)",
        identifiers: [
          { type: "CVE", name: "CVE-2019-11580" }
        ],
        severity: 1,
        category: "vulnerability",
        status: "confirmed",
        description:
          "Atlassian Crowd and Crowd Data Center had the pdkinstall development plugin incorrectly enabled in release builds. " +
          "Attackers who can send unauthenticated or authenticated requests to a Crowd or Crowd Data Center instance can exploit " +
          "this vulnerability to install arbitrary plugins, which permits remote code execution on systems running a vulnerable " +
          "version of Crowd or Crowd Data Center.",
        affected_software: [
          { vendor: "Atlassian", product: "Crowd" }
        ],
        references: [
          { type: "description", uri: "https://nvd.nist.gov/vuln/detail/cve-2019-11580" },
          { type: "description", uri: "https://confluence.atlassian.com/crowd/crowd-security-advisory-2019-05-22-970260700.html" },
          { type: "exploit", uri: "https://www.tenable.com/blog/cve-2019-11580-proof-of-concept-for-critical-atlassian-crowd-remote-code-execution" }
        ],
        authors: ["Corben Leo", "dwisiswant0", "shpendk"]
      }.merge!(instance_details)
      end
    end
  end

  module Task
    class AtlassianCrowdCve201911580 < BaseCheck
      def self.check_metadata
        {
          allowed_types: ["Uri"]
        }
      end

      # return truthy value to create an issue
      def check
        # run a nuclei 
        uri = _get_entity_name
        template = "cves/2019/CVE-2019-11580"

        # if this returns truthy value, an issue will be raised
        # the truthy value will be added as proof to the issue
        run_nuclei_template uri, template
      end
    end
  end
end