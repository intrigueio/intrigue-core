module Intrigue
  module Issue
  class SonatypeNexusCve202010204 < BaseIssue
  
    def self.generate(instance_details={})
  
      to_return = {
        added: "2020-01-01",
        name: "sonatype_nexus_cve_2020_10204",
        pretty_name: "Sonatype Nexus (CVE-2020-10204)",
        category: "vulnerability",
        severity: 3,
        status: "confirmed",
        description: "Sonatype Nexus Repository before 3.21.2 allows Remote Code Execution.",
        remediation:  "Update the instance",
        affected_software: [
          { :vendor => "Sonatype", :product => "Nexus Repository Manager" }
        ],
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { type: "description", uri: "https://github.com/advisories/GHSA-8h56-v53h-5hhj" },
          { type: "description", uri: "https://support.sonatype.com/hc/en-us/articles/360044882533-CVE-2020-10199-Nexus-Repository-Manager-3-Remote-Code-Execution-2020-03-31" }
        ],
        task: "vuln/sonatype_nexus_cve_2020_10204"
      }.merge(instance_details)
      
    to_return
    end
  
  end
  end
  end