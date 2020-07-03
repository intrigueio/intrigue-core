module Intrigue
module Issue
class JenkinsCreateProjectsUnauthenticated < BaseIssue

  def self.generate(instance_details={})
    to_return = {
      name: "jenkins_create_projects_unauthenticated",
      pretty_name: "Jenkins Misconfiguration - Anauthenticated Users can create Projects",
      severity: 1,
      references: [
        { type: "description", uri: "https://github.com/google/tsunami-security-scanner-plugins/blob/master/google/detectors/exposedui/jenkins/src/main/java/com/google/tsunami/plugins/detectors/exposedui/jenkins/JenkinsExposedUiDetector.java" }
      ],
      category: "application",
      status: "confirmed",
      affected_software: [ { :vendor => "Jenkins", :product => "Jenkins" } ],
      description:  "Unauthenticated Jenkins instance allows anonymous users to create arbitrary" +
                    " projects, which usually leads to code downloading from the internet" +
                    " and remote code executions.", 
      check: "uri_brute_focused_content"
    }.merge!(instance_details)

  to_return
  end

end
end
end
