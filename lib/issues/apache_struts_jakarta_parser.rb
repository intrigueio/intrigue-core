module Intrigue
module Issue
class VulnApacheStrutsJakartaParser20175638 < BaseIssue

  def self.generate(instance_details={})
    {
      name: "apache_struts_jakarta_parser",
      pretty_name: "Vulnerable Apache Struts Jakarta Parser (CVE-2017-5638)",
      identifiers: [
        { type: "CVE", name: "CVE-2017-5638" }
      ],
      severity: 1,
      status: "confirmed",
      category: "vulnerability",
      description: "A remote code execution vulnerability (CVE-2017-5638) in the Jakarta Multipart Parser in affected versions of the Apache Struts framework can enable a remote attacker to run arbitrary commands on the web server. Since its initial disclosure, this vulnerability has received significant attention, and has been exploited in the wild. Public exploits are also available for this vulnerability.", 
      remediation: "Customers are advised to immediately patch their servers to the latest versions of Apache Struts or implement recommended workarounds. See https://cwiki.apache.org/confluence/display/WW/S2-045 for more details.",
      affected_software: [
        { :vendor => "Apache", :product => "Struts", :version_from => "2.3.5", :version_to => "2.3.31" },
        { :vendor => "Apache", :product => "Struts", :version_from => "2.5.0", :version_to => "2.5.10" }
      ],
      references: [  # types: description, remediation, detection_rule, exploit, threat_intel
        { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2017-5638" },
        { type: "remediation", uri: "https://cwiki.apache.org/confluence/display/WW/S2-045" },
        { type: "detection_rule", uri: "https://exchange.xforce.ibmcloud.com/collection/Apache-Struts-Jakarta-Multipart-parser-code-execution-c7cfb0c86407ba72f6b5cb9fdbc98112" }, 
        { type: "exploit", uri: "https://packetstormsecurity.com/files/141494" },
        { type: "threat_intel", uri: "https://blog.rapid7.com/2017/03/09/apache-jakarta-vulnerability-attacks-in-the-wild/" }
      ],
      check: "vuln/apache_struts_jakarta_parser"
    }.merge!(instance_details)
  end

end
end
end


        