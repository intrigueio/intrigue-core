module Intrigue
  module Issue
  class AspnetElmahAxd < BaseIssue
  
    def self.generate(instance_details={})
      {
        name: "aspnet_elmah_axd",
        pretty_name: "ASP.NET Elmah.axd",
        severity: 3,
        category: "application",
        description: "Elmah.axd is a development library that retains full details about errors - including authenticated session information. This library can be dangerous when exposed to unauthenticated users.",
        remediation: "Adjust the security settings for the library or remove it. See: https://blog.elmah.io/elmah-security-and-allowremoteaccess-explained/.",
        affected: [ 
          { :vendor => "Microsoft", :product => "ASP.NET"},
        ],
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { type: "description", uri: "https://blog.elmah.io/elmah-tutorial/" },
          { type: "description", uri: "https://www.hanselman.com/blog/ELMAHErrorLoggingModulesAndHandlersForASPNETAndMVCToo.aspx" }, 
          { type: "remediation", uri: "https://blog.elmah.io/elmah-security-and-allowremoteaccess-explained/" }

        ]
      }.merge!(instance_details)
    end
  
  end
  end
  end
  
  
          