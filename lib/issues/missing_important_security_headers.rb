module Intrigue
module Issue
class MissingImportantSecurityHeaders < BaseIssue

  def self.generate(instance_details={})
    {
      added: "2020-01-01",
      name: "missing_important_security_headers",
      pretty_name: "Missing Important Application Security Headers",
      category: "misconfiguration",
      source: "URI",
      severity: 4,
      status: "confirmed",
      description: "One or more important security headers was missing from the URL.",
      references: [
        { type: "description", uri: "https://www.keycdn.com/blog/http-security-headers" }
      ],
    }.merge!(instance_details)
  end

end
end
end
