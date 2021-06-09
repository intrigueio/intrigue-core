module Intrigue
  module Issue
    class AtlassianCve202036289 < BaseIssue
      def self.generate(instance_details = {})
        {
          added: '2021-03-30',
          name: 'atlassian_jira_cve_2020_36289',
          pretty_name: 'Atlassian Jira Unauthenticated User Enumeration (CVE-2020-36289)',
          severity: 4,
          category: 'vulnerability',
          status: 'confirmed',
          description: 'Affected versions of Atlassian Jira Server and Data Center allow an unauthenticated user to enumerate users via an Information Disclosure vulnerability in the QueryComponentRendererValue!Default.jspa endpoint. The affected versions are before version 8.5.13, from version 8.6.0 before 8.13.5, and from version 8.14.0 before 8.15.1.',
          identifiers: [
            { type: 'CVE', name: 'CVE-2020-36289' }
          ],
          affected_software: [
            { vendor: 'Atlassian', product: 'Jira' }
          ],
          references: [
            { type: 'description', uri: 'https://nvd.nist.gov/vuln/detail/CVE-2020-36289' },
            { type: 'description', uri: 'https://jira.atlassian.com/browse/JRASERVER-71559' }
          ],
          authors: ['__mn1__', 'dhiyaneshDk', 'maxim']
        }.merge!(instance_details)
      end
    end
  end

  module Task
    class AtlassianCve202036289 < BaseCheck
      def self.check_metadata
        {
          allowed_types: ['Uri']
        }
      end

      # return truthy value to create an issue
      def check
        # run a nuclei
        uri = _get_entity_name
        template = 'cves/2020/CVE-2020-36289'

        # if this returns truthy value, an issue will be raised
        # the truthy value will be added as proof to the issue
        run_nuclei_template uri, template
      end
    end
  end
end
