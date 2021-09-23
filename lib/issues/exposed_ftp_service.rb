module Intrigue
  module Issue
  class ExposedFtpService < BaseIssue

    def self.generate(instance_details={})
      {
        added: "2020-09-25",
        name: "exposed_ftp_service",
        pretty_name: "Exposed FTP Service",
        severity: 3,
        category: "misconfiguration",
        status: "confirmed",
        description: "A FTP service was found.",
        remediation: "Prevent access to this service, utilize a more modern and encrypted alternative such as FTPS.",
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        ],
        # task: handled in ident
      }.merge!(instance_details)
    end

  end
  end
  end