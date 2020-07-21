module Intrigue
  module Issue
  class JenkinsExposedPath < BaseIssue
  
    def self.generate(instance_details={})
      {
        added: "2020-01-01",
        name: "jenkins_exposed_path",
        pretty_name: "Jenkins Exposed Path",
        severity: 4,
        category: "application",
        status: "confirmed",
        description: "A misconfigured Jenkins server was identified.",
        remediation: "Investigate the configuration and adjust it to ensure this path is not unexpectedly exposed.",
        affected_software: [ { :vendor => "Jenkins", :product => "Jenkins" } ],
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        ],
        task: "uri_brute_focused_content"
      }.merge!(instance_details)
    end
  
  end
  end
  end