module Intrigue
  module Issue
    class MoodleCve202136394 < BaseIssue
      def self.generate(instance_details = {})
        {
        added: '2021-09-15',
        name: 'moodle_cve_2021_36394',
        pretty_name: 'Moodle Shibboleth Module Remote Code Execution Vulnerability (CVE-2021-36394)',
        identifiers: [
          { type: 'CVE', name: 'CVE-2021-36394' }
        ],
        severity: 2,
        category: 'vulnerability',
        status: 'potential',
        description:
          'The vulnerability allows a remote attacker to execute arbitrary code on the target system. ' +
          'This vulnerability exists due to improper input validation in the Shibboleth authentication plugin. ' +
          'A remote attacker can send a specially crafted request and execute arbitrary code on the target system. ' +
          'Successful exploitation of this vulnerability may result in complete compromise of the vulnerable system.',
        affected_software: [
          { vendor: 'Moodle', product: 'Moodle' }
        ],
        references: [
          { type: 'description', uri: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-36394' },
          { type: 'description', uri: 'https://haxolot.com/posts/2021/moodle_pre_auth_shibboleth_rce_part1/' }
        ],
        authors: ['adambakalar']
        }.merge!(instance_details)
      end
    end
  end
  
  module Task
    class MoodleCve202136394 < BaseCheck
      def self.check_metadata
        {
          allowed_types: ['Uri']
        }
      end

      # return truthy value to create an issue

      def check
        # get version for product
        detected_version = get_version_for_vendor_product(@entity, 'Moodle', 'Moodle')
        return false unless detected_version

        # list vulnerable versions
        vulnerable_versions = [
          '3.9',
          '3.9.0',
          '3.9.1',
          '3.9.2',
          '3.9.3',
          '3.9.4',
          '3.9.5',
          '3.9.6',
          '3.9.7',
          '3.10',
          '3.10.0',
          '3.10.1',
          '3.10.2',
          '3.10.3',
          '3.10.4',
          '3.11',
          '3.11.0'
        ]

        # compare the version we got to the vulnerable version list
        vulnerable_versions.each do |vulnerable_version|
          if compare_versions_by_operator(detected_version, '3.9', '<') || compare_versions_by_operator(detected_version, vulnerable_version, '=')
            return {vulnerable_version_identified: vulnerable_version}
          end
        end

        false
      end
    end
  end
end
