module Intrigue
  module Issue
  class JiraIconuriservletSsrfCve20179506 < BaseIssue
  
    def self.generate(instance_details={})
  
      to_return = {
        name: "jira_iconuriservlet_ssrf_cve_2017_9506",
        pretty_name: "Jira IconURIServlet SSRF (CVE-2017-9506)",
        category: "application",
        severity: 2,
        status: "confirmed",
        description: "We detected a jira instance with an SSRF in the IconURIServlet component. This SSRF can be used to explore the target network.",
        remediation:  "Update your jira instance",
        affected_software: [
          { :vendor => "Atlassian", :product => "Jira" }
        ],
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { type: "description", uri: "https://www.acunetix.com/vulnerabilities/web/atlassian-oauth-plugin-iconuriservlet-ssrf/" }
        ],
        check: "uri_brute_focused_content"
      }.merge(instance_details)
      
    to_return
    end
  
  end
  end
  end