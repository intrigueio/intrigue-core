module Intrigue
  module Issue
  class GratuitiousExternalResourcesRequested < BaseIssue
  
    def self.generate(instance_details={})
      {
        added: "2020-01-01",
        name: "gratuitous_external_resources_requested",
        pretty_name: "Abnormally Large Number of External Resources",
        severity: 5,
        category: "misconfiguration",
        status: "confirmed",
        description: "When a browser requested the resource, a large number of requests were made to external hosts. In itself, this may not be a security problem, but can introduce more attack surface than necessary, and is indicative of poor security hygiene, as well as slow load times for a service.",
        remediation: "Investigate the resource, and determine if this behavior is expected.",
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        ]
      }.merge!(instance_details)
    end
  
  end
  end
  end
  