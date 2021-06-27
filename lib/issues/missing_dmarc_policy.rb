module Intrigue
module Issue
class MissingDmarcPolicy < BaseIssue

  def self.generate(instance_details={})
    {
      added: "2020-01-01",
      name: "missing_dmarc_policy",
      pretty_name: "Missing DMARC Policy",
      category: "misconfiguration", 
      source: "DNS",
      severity: 4,
      status: "confirmed",
      description: "The domain is missing a DMARC DNS record. DMARC is a way to make it easier for email senders and receivers to determine whether or not a given message is legitimately from the sender, and what to do if it isn't. This makes it easier to identify spam and phishing messages, and keep them out of peoples' inboxes. Example records can be found in the references.",
      references: [
        { type: "description", uri: "https://www.sparkpost.com/resources/email-explained/dmarc-explained/"},
        { type: "description", uri: "https://www.sonicwall.com/support/knowledge-base/what-is-a-dmarc-record-and-how-do-i-create-it-on-dns-server/170504796167071/"}
      ],
    }.merge!(instance_details)
  end

end
end
end