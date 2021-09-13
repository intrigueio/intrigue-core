module Intrigue
module Issue
class DefaultWebServerPageExposed < BaseIssue

  def self.generate(instance_details)
    to_return = {
      added: "2020-01-01",
      name: "default_web_server_page_exposed",
      pretty_name: "Default Web Server Page Exposed",
      severity: 5,
      status: "confirmed",
      category: "misconfiguration",
      description: "The web server is preseting a default page shown post-install. This is often an indicator that the server has not been hardened for Internet access.",
      remediation: "Inspect for sensitive files, and disable the pgage unless it's intentional.",
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        { type: "remediation", uri: "https://httpd.apache.org/docs/2.4/misc/security_tips.html"}
      ],
    }.merge!(instance_details)

  to_return
  end

end
end
  end
