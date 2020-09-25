module Intrigue
module Issue
class ExposedWebcamInterface < BaseIssue

  def self.generate(instance_details={})
    {
      added: "2020-09-25",
      name: "exposed_webcam_interface",
      pretty_name: "Exposed Webcam Interface",
      severity: 3, 
      category: "misconfiguration",
      status: "confirmed",
      description: "A webcam was found on the network.",
      remediation: "Prevent access to this webcam if it should not be exposed.",
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
      ],
      # task: handled in ident
    }.merge!(instance_details)
  end

end
end
end