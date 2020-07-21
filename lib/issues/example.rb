module Intrigue
module Issue
class Example < BaseIssue

  def self.generate(instance_details={})
    {
      added: "2020-01-01",
      name: "example",
      pretty_name: "Just an Example Issue",
      severity: 1,
      category: "network",
      status: "potential",
      description: "This example issue is terrible and you should drop everything to fix it!",
      remediation: "No patch is currently available, and only screaming seems to help.",
      affected_software: [ { :vendor => "Example Vendor", :product => "Example Product" } ],
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        { type: "description", uri: "https://allabouttheexamplevulnerability.com" },
        { type: "remediation", uri: "https://www.youtube.com/watch?v=FDv566DSTKg" }
      ]
    }.merge!(instance_details)
  end

end
end
end


        