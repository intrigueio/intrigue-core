
module Intrigue

  module Issue
    class SonicwallEmailSecurityApplianceCve202120021 < BaseIssue
      def self.generate(instance_details={})
      {
        added: "2021-04-22",
        name: "sonicwall_email_security_appliance_cve_2021_20021",
        pretty_name: "Sonicwall Email Security Appliance Unauthenticated Administrative Access (CVE-2021-20021)",
        identifiers: [
          { type: "CVE", name: "CVE-2021-20021" }
        ],
        severity: 1,
        status: "confirmed",
        category: "vulnerability",
        description: "A vulnerability in the SonicWall Email Security version versions 7.0.0-9.2.2 and 10.0.9.x allows unauthenticated access to an API. An attacker can use this API to create an administrative account by sending a crafted HTTP request to the remote host.",
        remediation: "Update to the latest version",
        affected_software: [
          { vendor: "Sonicwall", product: "Email Security Appliance"}
        ],
        references: [
          { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2021-20021" },
          { type: "exploit", uri: "https://www.fireeye.com/blog/threat-research/2021/04/zero-day-exploits-in-sonicwall-email-security-lead-to-compromise.html" },
          { type: "remediation", uri: "https://www.sonicwall.com/support/product-notification/security-notice-sonicwall-email-security-zero-day-vulnerabilities/210416112932360/" }
        ],
        authors: ["shpendk", "SonicWall PSIRT", "Charles Carmakal", "Ben Fedore", "Geoff Ackerman", "Andrew Thompson"]
      }.merge!(instance_details)
      end

    end
  end


  module Task
    class SonicwallEmailSecurityApplianceCve202120021 < BaseCheck
      def self.check_metadata
        {
          allowed_types: ["Uri"],
          example_entities: [{"type" => "Uri", "details" => {"name" => "https://intrigue.io"}}],
          allowed_options: []
        }
      end

      def check
        # lets try the default url first
        _log "Testing at /createou"
        uri_obj = URI(_get_entity_name)
        endpoint = "#{uri_obj.scheme}://#{uri_obj.hostname}:#{uri_obj.port}/createou?data=123"
        res = http_get_body endpoint
        if res =~ /Error in parsing request/
          _log "Vulnerable! Remote host tried to parse our data."
          return res
        end

        # if we didn't get a specific path, we failed :\
        if uri_obj.path == "" || uri_obj.path == "/"
          return nil
        end

        # ok we received a custom path, lets try it
        uri = "#{_get_entity_name}?data=123"
        res = http_get_body uri
        if res =~ /Error in parsing request/
          _log "Vulnerable! Remote host tried to parse our data."
          return res
        end

        return nil
      end
    end
  end

end