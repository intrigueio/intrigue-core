module Intrigue
  module Issue
  class SubdomainHijackEdgeCase < BaseIssue

    def self.generate(instance_details={})
      {
        added: "2020-07-26",
        name: "subdomain_hijack_edge_case",
        pretty_name: "Subdomain Vulnerable to Takeover (EDGE CASE)",
        severity: 3,
        category: "vulnerability",
        status: "potential",
        description:  "This subdomain appears to be pointing to a third party host " +
            " but it is unclaimed on the host and can be registered as part of their user-facing functionality" +
             ", allowing a malicious users to claim and host untrusted content on the domain. " +
             "NOTE! This subdomain takeover is rated lower, as the condition is only exploitable under " +
             "an edge case. ",
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { type: "description", uri: "https://dzone.com/articles/what-are-subdomain-takeovers-how-to-test-and-avoid" },
          { type: "description", uri: "https://labs.detectify.com/2014/10/21/hostile-subdomain-takeover-using-herokugithubdesk-more/" },
          { type: "remediation", uri: "http://claudijd.github.io/2017/02/06/preventing-subdomain-takeover/" },
          { type: "remediation", uri: "https://www.firecompass.com/blog/2-ways-to-identify-prevent-subdomain-takeover-vulnerability/" }
        ],
        task: "uri_check_subdomain_hijack"
      }.merge!(instance_details)
    end

  end
  end
  end
