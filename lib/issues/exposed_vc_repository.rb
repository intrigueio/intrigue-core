module Intrigue
  module Issue
  class ExposedVcRepository < BaseIssue
  
    def self.generate(instance_details={})
      to_return = {
        added: "2020-01-01",
        name: "exposed_vc_repository",
        pretty_name: "Exposed Version Control Repository",
        severity: 2,
        status: "confirmed",
        category: "vulnerability",
        description: "A version control repository was found on this webserver, and may be leaking content as account details, passwords, or other sensitive information.",
        remediation: "Block access to the repository using a .htaccess or similar method. Leaked repositories should be pulled down locally to your system and checked for sensitive content.",
        references: [
          { type: "description", uri: "https://royduineveld.nl/hacking-public-git-repositories/" },
          { type: "description", uri: "https://pentester.land/tutorials/2018/10/25/source-code-disclosure-via-exposed-git-folder.html" },
          { type: "exploit", uri: "https://github.com/internetwache/GitTools/tree/master/Dumper" }
        ], 
        check: "uri_brute_focused_content"
      }.merge!(instance_details)
    to_return
    end
  
  end
  end
  end
  