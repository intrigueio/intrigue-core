module Intrigue
module Issue
class CitrixNetscalerCve201919871 < BaseIssue

  def self.generate(instance_details={})
    {
      name: "citrix_netscaler_rce_cve_2019_19781",
      pretty_name: "Vulnerable Citrix Netscaler (CVE-2019-19781)",
      identifiers: [
        { type: "CVE", name: "CVE-2019-19871" }
      ],
      severity: 1,
      category: "vulnerability",
      status: "confirmed",
      description: "A remote pre-auth RCE path traversal vulnerability in Citrix NetScaler affecting devices in " + 
                   "the default configuration. Existence of the vulnerability was announced by Citrix in late Dec 2019 " +
                   "with no patch immediately released. Exploits are now available and active exploitation has been detected in the wild.", 
      remediation: "Apply the patch provided by Citrix (see references).",
      affected_software: [
        { :vendor => "Citrix", :product => "NetScaler Gateway", :version => "13.0" },
        { :vendor => "Citrix", :product => "NetScaler Gateway", :version => "12.1" },
        { :vendor => "Citrix", :product => "NetScaler Gateway", :version => "12.0" },
        { :vendor => "Citrix", :product => "NetScaler Gateway", :version => "11.1" },
        { :vendor => "Citrix", :product => "NetScaler Gateway", :version => "10.5" }
      ],
      references: [
        { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2019-19781" },
        { type: "description", uri: "https://www.tripwire.com/state-of-security/vert/citrix-netscaler-cve-2019-19781-what-you-need-to-know/" },
        { type: "description", uri: "https://www.trustedsec.com/blog/critical-exposure-in-citrix-adc-netscaler-unauthenticated-remote-code-execution/"},
        { type: "description", uri: "https://isc.sans.edu/diary/25686" },
        { type: "description", uri: "https://www.mdsec.co.uk/2020/01/deep-dive-to-citrix-adc-remote-code-execution-cve-2019-19781/"},
        { type: "remediation", uri: "https://support.citrix.com/article/CTX267027" },
        { type: "remediation", uri: "https://support.citrix.com/article/CTX267679" },
        { type: "remediation", uri: "https://support.citrix.com/article/CTX267027" },
        { type: "detection_rule", uri: "https://github.com/Neo23x0/sigma/blob/master/rules/web/web_citrix_cve_2019_19781_exploit.yml" }, 
        { type: "detection_rule", uri: "https://www.reddit.com/r/netsec/comments/en4mmo/multiple_exploits_for_cve201919781_citrix/" },
        { type: "exploit", uri: "https://github.com/trustedsec/cve-2019-19781" },
        { type: "exploit", uri: "https://www.exploit-db.com/exploits/47901" },
        { type: "threat_intel", uri: "https://isc.sans.edu/forums/diary/Citrix+ADC+Exploits+are+Public+and+Heavily+Used+Attempts+to+Install+Backdoor/25700/" },
        { type: "threat_intel", uri: "https://www.trustedsec.com/blog/netscaler-remote-code-execution-forensics" }
      ],
      check: "vuln/citrix_netscaler_rce_cve_2019_19781"
    }.merge!(instance_details)
  end

end
end
end


        
