module Intrigue
  module Issue
  class OpenGitlabRegistration < BaseIssue
  
    def self.generate(instance_details={})
      to_return = {
        added: "2020-01-01",
        name: "open_gitlab_registration",
        pretty_name: "Open Gitlab Registration",
        severity: 2,
        status: "confirmed",
        category: "misconfiguration",
        description: "This server allows anonymous users to register.",
        remediation: "Verify that anonymous users should be able to register on this server.",
        affected_software: [ 
          { :vendor => "Gitlab", :product => "Gitlab" }
        ],
        references: [
          { type: "description", uri: "https://gitlab.com/gitlab-org/gitlab-foss/issues/66124"},
          { type: "remediation", uri: "https://computingforgeeks.com/how-to-disable-user-creation-signup-on-gitlab-welcome-page/"}
        ], 
        task: "vuln/saas_gitlab_open_reg_check"
      }.merge!(instance_details)
  
    to_return
    end
  
  end
  end
  end
  