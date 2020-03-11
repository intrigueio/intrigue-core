module Intrigue
module Issue
class MissingDmarcPolicy < BaseIssue

  def self.generate(instance_details={})
    {
      name: "missing_dmarc_policy",
      pretty_name: "Missing DMARC Policy",
      category: "email", 
      source: "DNS",
      severity: 4,
      status: "confirmed",
      description: "DMARC is a policy (configured in a DNS record) that explains the email authentication practices for a given domain. When configured, it helps prevent spam and other abuses. In practice, it simply provides a receiving mail server (upon receipt of a new email) with enough information to  determine the validity of a sender. All domains configured to send email should implement DMARC, as it is one of the most important steps that can be taken to improve email deliverability.",
      references: [
        { type: "description", uri: "https://www.sparkpost.com/resources/email-explained/dmarc-explained/"},
        { type: "description", uri: "https://www.sonicwall.com/support/knowledge-base/what-is-a-dmarc-record-and-how-do-i-create-it-on-dns-server/170504796167071/"}
      ],
    }.merge!(instance_details)
  end

end
end
end