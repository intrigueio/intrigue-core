module Intrigue
  module Issue
  class ExposedWerkzeugDebugger < BaseIssue
  
    def self.generate(instance_details={})
      {
        added: "2020-06-15",
        name: "exposed_werkzeug_debugger",
        pretty_name: "A Werkzeug debuggging console is exposed",
        severity: 1, # default
        category: "application",
        status: "confirmed",
        description:  "Werkzeug is a debugger for Flask Python applications. This panel should not be exposed " + 
                      "to non-development enviornments, and can lead to remote compromise. It is known to have " + 
                      "been used in high profile breaches.",
        remediation: "Prevent access to this panel by placing it behind a firewall or otherwise restricting access",
        affected_software: [
          { :vendor => "Pallets Projects", :product => "Werkzeug" }
        ],
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { :type => "threat_intel", :uri => "https://labs.detectify.com/2015/10/02/how-patreon-got-hacked-publicly-exposed-werkzeug-debugger/" } 
        ],
        # task: handled in ident
      }.merge!(instance_details)
    end
  
  end
  end
  end