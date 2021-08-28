module Intrigue
  module Issue
  class GenericContentIssue < BaseIssue

    def self.generate(instance_details={})
      to_return = {
        added: "2020-01-01",
        name: "generic_content_issue",
        pretty_name: "Generic Content Issue",
        category: "misconfiguration",
        source: instance_details["check"],
        severity: 4,
        status: "confirmed",
        description: "This server had a content issue.",
        references: [],
        details: {
          uri: instance_details["uri"],
          task: instance_details["check"]
        }
      }.merge!(instance_details)
    to_return
    end

  end
  end
  end
