module Intrigue
  module Issue
  class AtlassianJiraOathPluginSSRF < BaseIssue
  
    def self.generate(instance_details={})
      {
        name: "atlassian_jira_oauth_plugin_ssrf",
        pretty_name: "Atlassian Jira OAuth Plugin SSRF (CVE-2017-9506)",
        identifiers: [
          { type: "CVE", name: "CVE-2017-9506" }
        ],
        severity: 1,
        category: "application",
        status: "confirmed",
        description: "This Jira instance is vulnerable to SSRF via the OAuth plugin.",
        remediation: "Upgrade your Jira Instance",
        affected_software: [ 
          { :vendor => "Atlassian", :product => "Jira" } ],
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { type: "description", uri: "http://dontpanic.42.nl/2017/12/there-is-proxy-in-your-atlassian.html?m=1" },
          { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2017-9506" },
          { type: "description", uri: "https://twitter.com/Zer0Security/status/983529439433777152" },
          { type: "description", uri: "https://medium.com/bugbountywriteup/piercing-the-veil-server-side-request-forgery-to-niprnet-access-c358fd5e249a" }
        ],
        check: "vuln/atlassian_jira_oath_plugin_ssrf"
      }.merge!(instance_details)
    end
  
  end
  end
  end
  