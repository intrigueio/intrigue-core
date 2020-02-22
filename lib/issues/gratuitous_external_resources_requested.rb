module Intrigue
  module Issue
  class GratuitiousExternalResourcesRequested < BaseIssue
  
    def self.generate(instance_details={})
      {
        name: "c",
        pretty_name: "Abnormally Large Number of External Resources",
        severity: 5,
        category: "application",
        description: "When a browser requested the resource, a large number of requests weree made to external hosts. In itself, this may not be a security problem, but can introduce more attack surface than necessary, and is indicative of poor security hygiene, as well as slow load times for a service.",
        remediation: "Investigate the resource, and determine if this behavior is expected.",
        affected_software: [ ],
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        ]
      }.merge!(instance_details)
    end
  
  end
  end
  end
  