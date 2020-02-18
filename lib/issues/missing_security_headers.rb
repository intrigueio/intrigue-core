module Intrigue
module Issue
class MissingSecurityHeaders < BaseIssue

  def self.generate(instance_details={})
    {
      name: "missing_security_headers",
      pretty_name: "Missing Security Headers",
      category: "network",
      source: "URI",
      severity: 5,
      status: "confirmed",
      description: "One or more security headers was missing from the URI",
      references: [
        "https://www.keycdn.com/blog/http-security-headers"
      ],
    }.merge!(instance_details)
  end

end
end
end
