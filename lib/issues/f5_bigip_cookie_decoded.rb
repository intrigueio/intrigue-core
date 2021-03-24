module Intrigue
  module Issue
    class F5BigIpCookieDecoder < BaseIssue
      def self.generate(instance_details = {})
        {
          name: "f5_bigip_cookie_decoded",
          pretty_name: "F5 BigIP Cookie Decoded",
          severity: 5,
          status: "confirmed",
          category: "threat",
          description: "The F5 BigIP Cookie can be decoded to leak information about the backend such as the Pool Name, IP Address, and Port",
          remediation: "Encrypt the cookies between the BIG-IP System and the Client.",
          affected_software: [
            { :vendor => "F5", :product => "BIG-IP Local Traffic Manager" },
          ],
          references: [ # types: description, remediation, detection_rule, exploit, threat_intel
            { type: "description", uri: "https://www.tenable.com/plugins/nessus/20089" },
            { type: "remediation", uri: "https://support.f5.com/csp/article/K14784" },
            { type: "exploit", uri: "https://github.com/rapid7/metasploit-framework/blob/master/modules/auxiliary/gather/f5_bigip_cookie_disclosure.rb" },
          ],
          check: "f5_bigip_cookie_decoder" 
	}.merge!(instance_details)
      end
    end
  end
end
