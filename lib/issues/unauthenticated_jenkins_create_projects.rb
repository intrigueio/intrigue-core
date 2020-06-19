module Intrigue
  module Issue
  class UnauthenticatedJenkinsCreateProjects < BaseIssue
  
    def self.generate(instance_details={})
      to_return = {
        name: "unauthenticated_jenkins_create_projects",
        pretty_name: "Unauthenicated Users can create Projects in Jenkins",
        severity: 1,
        references: [
          "https://github.com/google/tsunami-security-scanner-plugins/blob/master/google/detectors/exposedui/jenkins/src/main/java/com/google/tsunami/plugins/detectors/exposedui/jenkins/JenkinsExposedUiDetector.java"
        ],
        category: "application",
        status: "confirmed",
        description:  "Unauthenticated Jenkins instance allows anonymous users to create arbitrary" +
                      " projects, which usually leads to code downloading from the internet" +
                      " and remote code executions."
      }.merge!(instance_details)
  
    to_return
    end
  
  end
  end
  end
  