module Intrigue
  module Issue
    class AtlassianConfluence202126084 < BaseIssue
      def self.generate(instance_details = {})
        {
          added: '2021-09-01',
          name: 'atlassian_confluence_cve_2021_26084',
          pretty_name: 'Atlassian Confluence Server Arbitrary Code Execution (CVE-2021-26084)',
          severity: 1,
          category: 'vulnerability',
          status: 'confirmed',
          description: 'An OGNL injection vulnerability exists that would allow an authenticated user, and in some instances unauthenticated user, to execute arbitrary code on a Confluence Server or Data Center instance.',
          identifiers: [
            { type: 'CVE', name: 'CVE-2021-26084' }
          ],
          affected_software: [
            { vendor: 'Atlassian', product: 'Confluence' }
          ],
          references: [
            { type: 'description', uri: 'https://jira.atlassian.com/browse/CONFSERVER-67940' },
            { type: 'description', uri: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=2021-26084' }
          ],
          authors: %w[SnowyOwl dhiyaneshDk maxim]
        }.merge!(instance_details)
      end
    end
  end

  module Task
    class AtlassianConfluence202126084 < BaseCheck
      def self.check_metadata
        {
          allowed_types: ['Uri']
        }
      end

      # return truthy value to create an issue
      def check
        # run a nuclei
        uri = _get_entity_name
        _log "Running on #{uri}"

        template = 'cves/2021/CVE-2021-26084'

        # if this returns truthy value, an issue will be raised
        # the truthy value will be added as proof to the issue
      run_nuclei_template uri, template
      end

    end
  end
end
