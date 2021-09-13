module Intrigue
module Issue
class Pastebin < BaseIssue

  def self.generate(instance_details={})
    to_return = {
      added: "2020-01-15",
      name: "suspicious_pastebin",
      pretty_name: "Pastebin Data Detected",
      severity: 5,
      status: "confirmed",
      category: "leak",
      description: "Related account found in pastebin page",
      remediation: "Mention in pastebin should be investigated by your team it might contain leaked data or some private data related to your company",
      references: [
        { type: "description", uri: "https://www.authentic8.com/blog/how-to-use-pastebin-for-cyber-threat-intelligence-research" }
      ]
    }.merge!(instance_details)

  to_return
  end

end
end
end
