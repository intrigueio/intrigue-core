module Intrigue
  module Issue
    class OracleWeblogicCve20212109 < BaseIssue
      def self.generate(instance_details = {})
        {
          added: '2021-05-29',
          name: 'oracle_weblogic_cve_2021_2109',
          pretty_name: 'Oracle WebLogic Server Administration Console Handle Remote Code Execution (CVE-2021-2109)',
          identifiers: [
            { type: 'CVE', name: 'CVE-2021-2109' }
          ],
          severity: 2,
          category: 'vulnerability',
          status: 'confirmed',
          description:
            'Oracle Weblogic versions 10.3.6.0.0, 12.1.3.0.0, 12.2.1.3.0, 12.2.1.4.0 and 14.1.1.0.0 are vulnerable to a ' +
              'remote code execution vulnerability. A high privileged attacker with network access via HTTP ' +
              'can execute arbitrary commands which may lead to total takeover of the underlying server. ',
          affected_software: [
            { vendor: 'Oracle', product: 'WebLogic' },
            { vendor: 'Oracle', product: 'WebLogic Server' }
          ],
          references: [
            { type: 'description', uri: 'https://nvd.nist.gov/vuln/detail/CVE-2021-2109' },
            { type: 'description', uri: 'https://www.oracle.com/security-alerts/cpujan2021.html' }
          ],
          authors: ['adambakalar']
        }.merge!(instance_details)
      end
    end
  end

  module Task
    class OracleWeblogicCve20212109 < BaseCheck
      def self.check_metadata
        {
          allowed_types: ['NetworkService']
        }
      end

      # return truthy value to create an issue

      def check
        
        fingerprints = @entity.get_detail("fingerprint")
        
        # get version for product
        version = get_version_for_vendor_product(@entity, 'Oracle', 'WebLogic Server')
        return false unless version

        # list vulnerable versions
        vulnerable_versions = [
          '10.3.6.0',
          '10.3.6.0.0',
          '12.1.3.0',
          '12.1.3.0.0',
          '12.2.1.3',
          '12.2.1.3.0',
          '12.2.1.4',
          '12.2.1.4.0',
          '14.1.1.0',
          '14.1.1.0.0'
        ]

        # compare the version we got to the vulnerable version list
        vulnerable_versions.each do |vulnerable_version|
          return {vulnerable_version_identified: vulnerable_version} if compare_versions_by_operator(version, vulnerable_version, '=')
        end

      false
      end
    end
  end
end
