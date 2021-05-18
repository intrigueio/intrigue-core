module Intrigue
  module Issue
    class CiscoSmartInstallRceCve20180151 < BaseIssue
      def self.generate(instance_details={})
        {
          added: "2021-05-18",
          pretty_name: "Cisco Smart Install Remote Code Execution (CVE-2018-0151)",
          name: "cisco_smartinstall_cve_2018_0151",
          category: "vulnerability",
          severity: 1,
          status: "potential",
          description: "Cisco Smart Install Remote Code Execution Vulnerability",
          remediation: "Update the device.",
          affected_software: [
            { :vendor => "Cisco", :product => "Smart Install" }
          ],
          references: [ # types: description, remediation, detection_rule, exploit, threat_intel
            { type: "description", uri: "https://tools.cisco.com/security/center/content/CiscoSecurityAdvisory/cisco-sa-20180328-qos" }, 
            { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2018-0151" },
            { type: "description", uri: "https://www.rapid7.com/blog/post/2018/03/29/cisco-smart-install-smi-remote-code-execution-what-you-need-to-know/" }
          ]
        }.merge(instance_details)
      end
    end
  end
end