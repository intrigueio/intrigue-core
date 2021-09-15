module Intrigue
module Issue
class SuspiciousCommit< BaseIssue

  def self.generate(instance_details={})
    to_return = {
      added: "2020-01-01",
      name: "suspicious_commit",
      pretty_name: "Suspicious Commit in Code Repository",
      severity: 2,
      status: "potential",
      category: "leak",
      description: "A suspicious commit was found in a public Github repository.",
      remediation: "Verify the GitHub repository and delete the file or the comment which expose sensitive information.",
      references: [
        { type: "description", uri: "https://docs.github.com/en/github/authenticating-to-github/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository" }
      ]
    }.merge!(instance_details)

  to_return
  end

end
end
end
