module Intrigue
module Issue
class SubdomainHijack < BaseIssue

  def self.generate(instance_details={})
    {
      added: "2020-01-01",
      name: "subdomain_hijack",
      pretty_name: "Subdomain Vulnerable to Takeover (aka Subdomain Hijack)",
      severity: 2,
      category: "vulnerability",
      status: "potential",
      description:  " This uri appears to be unclaimed on a third party host, meaning," +
                    " there's a DNS record on a domain that is in scope, pointing to a third party" +
                    " but it is unclaimed on the third party host and can be registered with" +
                    " the host, allowing users to host malicious content on the domain.",
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        { type: "description", uri: "https://dzone.com/articles/what-are-subdomain-takeovers-how-to-test-and-avoid" },
        { type: "description", uri: "https://labs.detectify.com/2014/10/21/hostile-subdomain-takeover-using-herokugithubdesk-more/" },
        { type: "remediation", uri: "http://claudijd.github.io/2017/02/06/preventing-subdomain-takeover/" },
        { type: "remediation", uri: "https://www.firecompass.com/blog/2-ways-to-identify-prevent-subdomain-takeover-vulnerability/" }
      ],
      check: "uri_check_subdomain_hijack"
    }.merge!(instance_details)
  end

end
end
end
