module Intrigue
module Issue
class VulnCitrixNetscalerCve201919871 < BaseIssue

  def self.generate(instance_details={})
    {
      name: "vulnerability_citrix_netscaler_rce_cve_2019_19781",
      pretty_name: "Vulnerable Citrix Netscaler (CVE-2019-19871)",
      identifiers: [
        { type: "CVE", name: "CVE-2019-19871" },
      ],
      severity: 1,
      category: "network",
      description: "A Citrix Netscaler device was found to be vulnerable to an unauthenticated RCE (CVE-2019-19781). The vulnerability was released in Dec 2019 and no patch was released immediately. Remote, Pre-auth Arbitrary Command Execution is possible due to the logic vulnerability.",
      remediation: "No patch is currently available, apply the workarounds provided by Citrix (see references).",
      affected_software: [ # TODO ... convert these to CPE?
        "Citrix ADC and Citrix Gateway version 13.0 all supported builds",
        "Citrix ADC and NetScaler Gateway version 12.1 all supported builds",
        "Citrix ADC and NetScaler Gateway version 12.0 all supported builds",
        "Citrix ADC and NetScaler Gateway version 12.0 all supported builds",
        "Citrix NetScaler ADC and NetScaler Gateway version 10.5 all supported builds"
      ],
      references: [
        { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2019-19781" },
        { type: "description", uri: "https://www.tripwire.com/state-of-security/vert/citrix-netscaler-cve-2019-19781-what-you-need-to-know/" },
        { type: "remediation", uri: "https://support.citrix.com/article/CTX267027" },
        { type: "remediation", uri: "https://support.citrix.com/article/CTX267679" },
        { type: "remediation", uri: "https://support.citrix.com/article/CTX267027" },
        { type: "exploitation", uri: "https://www.trustedsec.com/blog/critical-exposure-in-citrix-adc-netscaler-unauthenticated-remote-code-execution/" },
        { type: "detection", uri: "https://github.com/Neo23x0/sigma/blob/master/rules/web/web_citrix_cve_2019_19781_exploit.yml" }, 
        { type: "detection", uri: "https://www.reddit.com/r/netsec/comments/en4mmo/multiple_exploits_for_cve201919781_citrix/" },
        { type: "threat_intelligence", uri: "https://isc.sans.edu/forums/diary/Citrix+ADC+Exploits+are+Public+and+Heavily+Used+Attempts+to+Install+Backdoor/25700/" },
        { type: "threat_intelligence", uri: "https://www.trustedsec.com/blog/netscaler-remote-code-execution-forensics" }
      ]
    }.merge(instance_details)
  end

end
end
end


        