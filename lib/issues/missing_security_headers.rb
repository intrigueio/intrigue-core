module Intrigue
module Issue
class MissingSecurityHeaders < BaseIssue

  def self.generate(instance_details={})
    {
      added: "2020-01-01",
      name: "missing_security_headers",
      pretty_name: "Missing Application Security Headers",
      category: "application",
      source: "URI",
      severity: 5,
      status: "confirmed",
      description: "One or more security headers was missing from the URL.",
      references: [
        { type: "description", uri: "https://www.keycdn.com/blog/http-security-headers" }
      ],
    }.merge!(instance_details)
  end

end
end
end
