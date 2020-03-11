module Intrigue
module Issue
class SelfSignedCertif < BaseIssue

  def self.generate(instance_details={})
    {
      name: "self_signed_certificate",
      pretty_name: "Self Signed Certificate Detected",
      severity: 5,
      status: "confirmed",
      category: "application",
      description: "The following site is configured with a self-signed certificate",
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        { type: "description", uri: "https://security.stackexchange.com/questions/93162/how-to-know-if-certificate-is-self-signed/162263"}
      ]
    }.merge!(instance_details)
  end

end
end
end
