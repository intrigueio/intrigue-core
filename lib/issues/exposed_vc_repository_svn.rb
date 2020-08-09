module Intrigue
  module Issue
  class ExposedVcRepositorySvn < BaseIssue
  
    def self.generate(instance_details={})
      to_return = {
        added: "2020-01-01",
        name: "exposed_vc_repository_svn",
        pretty_name: "Exposed Version Control Repository (Subversion)",
        severity: 2,
        status: "confirmed",
        category: "vulnerability",
        description: "A version control repository was found, and may be leaking content as account details, passwords, or other sensitive information.",
        remediation: "Block access to the repository using an htaccess or similar file. Leaked repositories should be pulled down locally to your system and checked for sensitive content.",
        references: [
          { type: "description", uri: "https://medium.com/@ghostlulzhacks/exposed-source-code-c16fac0032ff"}, 
          { type: "exploit", uri: "https://github.com/anantshri/svn-extractor"},
        ], 
        check: "uri_brute_focused_content"
      }.merge!(instance_details)
    to_return
    end
  
  end
  end
  end
  