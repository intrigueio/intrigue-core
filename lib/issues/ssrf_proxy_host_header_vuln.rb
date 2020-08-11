module Intrigue
module Issue
class SsrfProxyHostHeaderVuln < BaseIssue

  def self.generate(instance_details={})
    {
      name: "ssrf_proxy_host_header_vuln",
      pretty_name: "SSRF Proxy Host Header Detected",
      severity: 3,
      category: "network",
      status: "potential",
      description: "Server Side Request Forgery (SSRF) vulnerabilities let an attacker send crafted requests from the back-end server of a vulnerable web application" +
       "Criminals usually use SSRF attacks to target internal systems that are behind firewalls and are not accessible from the external network.",
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        "https://www.acunetix.com/blog/articles/server-side-request-forgery-vulnerability/"
      ]
    }.merge!(instance_details)
  end

end
end
end
