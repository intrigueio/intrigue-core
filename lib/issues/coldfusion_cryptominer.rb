module Intrigue
module Issue
class ColdfusionCryptominer < BaseIssue

  def self.generate(instance_details={})
    {
      added: "2020-01-01",
      name: "coldfusion_cryptominer",
      pretty_name: "Coldfusion Cryptominer",
      severity: 1,
      category: "compromise",
      status: "potential",
      description: "A file matching the pattern of a cryptominer was found on this server.",
      remediation: "Investigate and determine if the server is affected. Remove the infection if so.",
      affected_software: [
        { :vendor => "Adobe", :product => "Coldfusion" }
      ],
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
      ],
      task: "uri_brute_focused_content"
    }.merge!(instance_details)
  end

end
end
end