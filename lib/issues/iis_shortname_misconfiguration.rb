module Intrigue
  module Issue
    class IIS_Shortnames < BaseIssue
      def self.generate(instance_details = {})
        {
          name: "iis_shortnames_misconfiguration",
          pretty_name: "Microsoft IIS Tilde (Shortname Files) Misconfiguration",
          severity: 3,
          status: "confirmed",
          category: "threat",          
          description: "Host is vulnerable to IIS Shortname Scanning. An attacker can bruteforce these shortnames to reveal partial filenames or directories.",
          remediation: "Discard all web requests using the tilde character and add a registry key named NtfsDisable8dot3NameCreation to HKLM\\SYSTEM\\CurrentControlSet\\Control\\FileSystem. Set the value of the key to 1 to mitigate all 8.3 name conventions on the server.",
          affected_software: [
            { :vendor => "Microsoft", :product => "Internet Information Services" },
          ],
          references: [ # types: description, remediation, detection_rule, exploit, threat_intel
            { type: "description", uri: "https://soroush.secproject.com/downloadable/microsoft_iis_tilde_character_vulnerability_feature.pdf" },
            { type: "remediation", uri: "https://support.detectify.com/support/solutions/articles/48001048944-microsoft-iis-tilde-vulnerability" },
            { type: "exploit", uri: "https://github.com/irsdl/IIS-ShortName-Scanner" },
          ],
          check: "iis_shortnames_misconfiguration"     
	}.merge!(instance_details)
      end
    end
  end
end
