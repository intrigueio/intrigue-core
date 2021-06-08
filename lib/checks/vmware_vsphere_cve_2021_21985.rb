module Intrigue
  module Issue
    class VmwareCve202121985 < BaseIssue
      def self.generate(instance_details = {})
        {
          added: '2021-06-08',
          name: 'vmware_cve_2021_21985',
          pretty_name: 'VMWare vSphere Client Remote Code Execution (CVE-2021-21985)',
          severity: 1,
          category: 'vulnerability',
          status: 'confirmed',
          description: 'The vSphere Client (HTML5) contains a remote code execution vulnerability due to lack of input validation in the Virtual SAN Health Check plug-in which is enabled by default in vCenter Server. A malicious actor with network access to port 443 may exploit this issue to execute commands with unrestricted privileges on the underlying operating system that hosts vCenter Server.',
          identifiers: [
            { type: 'CVE', name: 'CVE-2021-21985' }
          ],
          affected_software: [
            { vendor: 'VMware', product: 'vSphere' }
          ],
          references: [
            { type: 'description', uri: 'https://nvd.nist.gov/vuln/detail/CVE-2021-21985' },
            { type: 'description', uri: 'https://www.vmware.com/security/advisories/VMSA-2021-0010.html' },
            { type: 'exploit', uri: 'https://github.com/alt3kx/CVE-2021-21985_PoC' }
          ],
          authors: ['Ricter Z', 'D0rkerDevil', 'maxim']
        }.merge!(instance_details)
      end
    end
  end

  module Task
    class VmwareCve202121985 < BaseCheck
      def self.check_metadata
        {
          allowed_types: ['Uri']
        }
      end

      # return truthy value to create an issue
      def check
        # run a nuclei
        uri = _get_entity_name
        template = 'cves/2021/CVE-2021-21985'

        # if this returns truthy value, an issue will be raised
        # the truthy value will be added as proof to the issue
        run_nuclei_template uri, template
      end
    end
  end
end
