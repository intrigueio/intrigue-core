module Intrigue
  module Issue
  class VulnTomcatGhostcatCve20201938 < BaseIssue
  
    def self.generate(instance_details={})
      {
        name: "vulnerability_tomcat_ghostcat_cve_2020_1938",
        pretty_name: "Vulnerable Tomcat - Ghostcat (CVE-2020-1938)",
        identifiers: [
          { type: "CVE", name: "CVE-2020-1938" }
        ],
        severity: 1,
        category: "vulnerability",
        status: "confirmed",
        description: "When using the Apache JServ Protocol (AJP), care must be taken when trusting incoming connections to Apache Tomcat. Tomcat treats AJP connections as having higher trust than, for example, a similar HTTP connection. If such connections are available to an attacker, they can be exploited in ways that may be surprising. In Apache Tomcat 9.0.0.M1 to 9.0.0.30, 8.5.0 to 8.5.50 and 7.0.0 to 7.0.99, Tomcat shipped with an AJP Connector enabled by default that listened on all configured IP addresses. It was expected (and recommended in the security guide) that this Connector would be disabled if not required.",
        remediation: "Disable port 8009 and update the tomcat software.",
        affected_software: [
          { :vendor => "Tomcat", :product => "Tomcat", :version => "6" },
          { :vendor => "Tomcat", :product => "Tomcat", :version => "7" },
          { :vendor => "Tomcat", :product => "Tomcat", :version => "8" },
          { :vendor => "Tomcat", :product => "Tomcat", :version => "9" }
        ],
        references: [ # description, remediation, detection rule, exploit, threat intel
          { type: "description", uri: "https://www.chaitin.cn/en/ghostcat" },
          { type: "description", uri: "https://www.cnvd.org.cn/webinfo/show/5415?fbclid=IwAR1dLGGo7aOlR2DN2L0DEwzZFldFM-uAT8fYgkQXdvFcFBdQqhDtJbzSZec" },
          { type: "description", uri: "https://www.tenable.com/blog/cve-2020-1938-ghostcat-apache-tomcat-ajp-file-readinclusion-vulnerability-cnvd-2020-10487" },
          { type: "exploit", uri: "https://github.com/YDHCUI/CNVD-2020-10487-Tomcat-Ajp-lfi" },
          { type: "exploit", uri: "https://github.com/nibiwodong/CNVD-2020-10487-Tomcat-ajp-POC" },
          { type: "exploit", uri: "https://github.com/0nise/CVE-2020-1938" },
          { type: "exploit", uri: "https://github.com/xindongzhuaizhuai/CVE-2020-1938" },
          { type: "exploit", uri: "https://github.com/laolisafe/CVE-2020-1938" },
          { type: "threat_intel", uri: "https://twitter.com/hrbrmstr/status/1233766331314581509" },
          { type: "detection_rule", uri: "https://github.com/DaemonShao/CVE-2020-1938" }, 
          { type: "detection_rule", uri: "https://github.com/Neo23x0/signature-base/blob/master/yara/vul_cve_2020_1938.yar" }, 
          { type: "detection_rule", uri: "https://raw.githubusercontent.com/bhdresh/SnortRules/master/Exploit/CVE-2020-1938.rules" }, 
        ],
        check: "vuln/tomcat_ghostcat_cve_2020_1938"
      }.merge!(instance_details)
    end
  
  end
  end
  end
  
  
          
  