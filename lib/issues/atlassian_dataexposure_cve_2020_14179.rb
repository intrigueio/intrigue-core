module Intrigue
    module Issue
    class AtlassianCve202014179 < BaseIssue
  
      def self.generate(instance_details={})
        {
          added: "2020-09-22",
          name: "atlassian_dataexposure_cve_2020_14179",
          pretty_name: "Atlassian Sensitive Data Exposure CVE-2020-14179",
          identifiers: [
            { type: "CVE", name: "CVE-2020-14179" },
            { type: "CWE", name: "CWE-425" },
            { type: "CAPEC", name: "CAPEC-87" }
          ],
          severity: 3,
          category: "vulnerability",
          status: "potential",
          description: "Affected versions of Atlassian Jira Server and Data Center allow remote, unauthenticated attackers to view custom field names and custom SLA names via an Information Disclosure vulnerability in the /secure/QueryComponent!Default.jspa endpoint. The affected versions are before version 8.5.8, and from version 8.6.0 before 8.11.1.",
          remediation: "Update to version 8.5.8, 8.11.1 or 8.12.0 respectively.",
          affected_software: [
            { :vendor => "Atlassian", :product => "Jira" }
          ],
          references: [ # types: description, remediation, detection_rule, exploit, threat_intel
            { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2020-14179" },
            { type: "remediation", uri: "https://jira.atlassian.com/browse/JRASERVER-71536" },
  
          ],
          task: "vuln/atlassian_dataexposure_cve_2020_14179"
        }.merge!(instance_details)
      end
  
    end
    end
    end
  
