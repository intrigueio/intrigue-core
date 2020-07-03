module Intrigue
  module Issue
  class LeakedRepository < BaseIssue
  
    def self.generate(instance_details={})
      to_return = {
        name: "leaked_repository",
        pretty_name: "Leaked Repository",
        severity: 2,
        status: "confirmed",
        category: "leak",
        description: "A version control repository was found, and may be leaking content as account details, passwords, or other sensitive information.",
        remediation: "Block access to the repository using an htaccess or similar file. Leaked repositories should be pulled down locally to your system and checked for sensitive content.",
        references: [
          { type: "description", uri: "https://royduineveld.nl/hacking-public-git-repositories/"},
          { type: "description", uri: "https://pentester.land/tutorials/2018/10/25/source-code-disclosure-via-exposed-git-folder.html"},
        ], 
        check: "uri_brute_focused_content"
      }.merge!(instance_details)
    to_return
    end
  
  end
  end
  end
  