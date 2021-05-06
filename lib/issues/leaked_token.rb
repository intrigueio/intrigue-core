module Intrigue
  module Issue
  class LeakedToken < BaseIssue

    def self.generate(instance_details={})
      to_return = {
        added: "2020-01-01",
        name: "leaked_token",
        pretty_name: "Leaked Token Detected",
        severity: 2,
        status: "confirmed",
        category: "leak",
        description: "Sensitive token discovered.",
        remediation: "Leaked tokens should be reset and examined for suspicious activities. Trace back the loccation of the leak and adjust as nececssary to prevent new tokens from leaking in the same way.",
        references: [
          { type: "description", uri: "https://www.kaspersky.com/blog/tokens-on-github/26238/"},
          { type: "description", uri: "https://digitalguardian.com/blog/popular-spell-checking-extension-leaked-authentication-tokens"},
          { type: "remediation", uri: "https://support.google.com/googleapi/answer/6310037"}
        ]
      }.merge!(instance_details)

    to_return
    end

  end
  end
  end
