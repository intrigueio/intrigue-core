
module Intrigue

  module Issue
    class IBMMaximoCve20204463 < BaseIssue
      def self.generate(instance_details={})
      {
        added: "2021-03-30",
        name: "ibm_maximo_cve_2020_4463",
        pretty_name: "IBM Maximo XML External Entity Injection (CVE-2020-4463)",
        severity: 1,
        category: "vulnerability",
        status: "confirmed",
        description: "IBM Maximo Asset Management 7.6.0.1 and 7.6.0.2 is vulnerable to an XML External Entity Injection (XXE) attack when processing XML data. A remote attacker could exploit this vulnerability to expose sensitive information or consume memory resources. IBM X-Force ID: 181484.",
        identifiers: [
          { type: "CVE", name: "CVE-2020-4463" }
        ],
        affected_software: [ 
          { :vendor => "IBM", :product => "Maximo" }
        ],
        references: [
          { type: "description", uri: "https://nvd.nist.gov/vuln/detail/CVE-2020-4463" },
          { type: "description", uri: "https://www.ibm.com/support/pages/security-bulletin-ibm-maximo-asset-management-vulnerable-information-disclosure-cve-2020-4463" },
          { type: "exploit", uri: "https://github.com/Ibonok/CVE-2020-4463" }
        ],
        authors: ["Michael Wollner", "dwisiswant0", "maxim"]
      }.merge!(instance_details)
      end
    end
  end

  module Task
    class IBMMaximoCve20204463 < BaseCheck
      def self.check_metadata
        {
          allowed_types: ['Uri']
        }
      end

      # return truthy value to create an issue
      def check

        # run a nuclei
        uri = _get_entity_name
        template = 'cves/2020/CVE-2020-4463'

        # if this returns truthy value, an issue will be raised
        # the truthy value will be added as proof to the issue
        run_nuclei_template uri, template
      end

    end
  end
end
