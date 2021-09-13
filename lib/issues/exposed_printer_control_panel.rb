module Intrigue
  module Issue
  class ExposedPrinterControlPanel < BaseIssue

    def self.generate(instance_details={})
      {
        added: "2020-01-01",
        name: "exposed_printer_control_panel",
        pretty_name: "Exposed Printer Control Panel",
        severity: 2, # default
        category: "misconfiguration",
        status: "confirmed",
        description: "A printer control panel was discovered. Printers should not be exposed to unauthenticated users",
        remediation: "Prevent access to this panel by placing it behind a firewall or otherwise restricting access",
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { :type => "threat_intel", :uri => "https://www.zdnet.com/article/80000-printers-are-exposing-their-ipp-port-online/" },
          { :type => "threat_intel", :uri => "https://www.vice.com/en_us/article/nzqayz/this-teen-hacked-150000-printers-to-show-how-the-internet-of-things-is-shit" }
        ],
        # task: handled in ident
      }.merge!(instance_details)
    end

  end
  end
  end