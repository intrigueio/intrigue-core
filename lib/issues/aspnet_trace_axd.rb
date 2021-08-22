module Intrigue
  module Issue
  class AspnetTraceAxd < BaseIssue

    def self.generate(instance_details={})
      {
        added: "2020-01-01",
        name: "aspnet_trace_axd",
        pretty_name: "ASP.NET Trace.axd Information Leak",
        severity: 4,
        category: "misconfiguration",
        status: "confirmed",
        description: "Trace.axd leaks sensitive information. The page exposes the full version details of the ASP.NET libraries in the best case, and sensitive information (application contents) in the worst case. Best practice is to disable it in production.",
        remediation: "Disable error tracing in your web.config.",
        affected_software: [
          { :vendor => "Microsoft", :product => "ASP.NET" }
        ],
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { type: "description", uri: "https://hackerone.com/reports/519418" },
          { type: "remediation", uri: "https://www.netsparker.com/web-vulnerability-scanner/vulnerabilities/traceaxd-detected/" }
        ],
        task: "uri_brute_focused_content"
      }.merge!(instance_details)
    end

  end
  end
  end


