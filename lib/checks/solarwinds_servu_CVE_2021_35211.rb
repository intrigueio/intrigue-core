module Intrigue
  module Issue
    class SolarwindsServuCve202135211 < BaseIssue
      def self.generate(instance_details = {})
        {
          added: '2021-07-13',
          name: 'solarwinds_servu_CVE_2021_35211.rb',
          pretty_name: 'SolarWinds Serv-U Remote Code Execution (CVE-2021-35211)',
          identifiers: [
            { type: 'CVE', name: 'CVE-2021-35211' }
          ],
          severity: 1,
          category: 'vulnerability',
          status: 'potential',
          description: 'Remote code execution vulnerability in Serv-U 15.2.3 HF1 and all prior Serv-U versions',
          affected_software: [
            { vendor: 'SolarWinds', product: 'Serv-U' }
          ],
          references: [
            { type: 'description', uri: 'https://nvd.nist.gov/vuln/detail/CVE-2021-35211' },
            { type: 'description',
              uri: 'https://www.helpnetsecurity.com/2021/07/13/solarwinds-patches-zero-day-exploited-in-the-wild-cve-2021-35211/' }
          ],
          authors: ['shpendk']
        }.merge!(instance_details)
      end
    end
  end

  module Task
    class SolarwindsServuCve202135211 < BaseCheck
      def self.check_metadata
        {
          # Serv-U is not affected if ssh is enabled, hence only URI accepted here (see helpnetsecurity description for more details)
          allowed_types: ['Uri'] 
        }
      end

      # return truthy value to create an issue
      def check
        # get enriched entity
        require_enrichment

        # get version for product
        version = get_version_for_vendor_product(@entity, 'SolarWinds', 'Serv-U')
        return false unless version

        # if its vulnerable, return some proof
        if compare_versions_by_operator(version, '15.2.3', '<=')
          return "Asset is vulnerable based on fingerprinted version #{version}"
        end
      end
    end
  end
end
