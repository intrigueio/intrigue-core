module Intrigue
module Issue
class Pastebin < BaseIssue

  def self.generate(instance_details={})
    to_return = {
      added: "2020-01-15",
      name: "suspicious_pastebin",
      pretty_name: "Pastebin Data Detected",
      severity: 3,
      status: "confirmed",
      category: "leak",
      description: "Related account found in pastebin page",
      remediation: "Mention in Pastebin should be investigated by your team it might contain leaked data or some private data related to your company",
      references: []
    }.merge!(instance_details)

  to_return
  end

end
end
end
