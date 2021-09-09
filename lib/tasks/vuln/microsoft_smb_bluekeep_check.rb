###
### Task is in good shape, just needs some option parsing, and needs to deal with paths
###

module Intrigue
module Task
class MicrosoftSmbBluekeepCheck < BaseTask

  include Intrigue::Task::Dns

  def self.metadata
    {
      :name => "vuln/microsoft_smb_bluekeep_check",
      :pretty_name => "Microsoft SMB Bluekeep Check",
      :authors => ["jcran", "@ErrataRob"],
      :identifiers => [{ "cve" => "CVE-2019-0708" }],
      :description => "This task runs a rdpscan scan on the target host or domain and creates an issue if found vulnerable to Bluekeep.",
      :references => [],
      :type => "vuln_check",
      :passive => false,
      :allowed_types => ["IpAddress","NetworkService"],
      :example_entities => [{"type" => "IpAddress", "details" => {"name" => "10.0.0.1"}}],
      :allowed_options => [],
      :created_types => [ ]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    if _get_entity_type_string == "IpAddress"
      # Get range, or host
      to_scan = _get_entity_name
    elsif _get_entity_type_string == "NetworkService"
      #x.x.x.x:22 
      to_scan = _get_entity_name.split(":").first 
    end 

    # shell out to masscan and run the scan
    # TODO - move this to scanner mixin
    masscan_string = "rdpscan #{to_scan}"
    masscan_string = "sudo #{masscan_string}" unless Process.uid == 0

    _log "Running... #{masscan_string}"
    output = _unsafe_system(masscan_string)

    if output =~ /SAFE/
      _log_good "Safe! #{output.strip}"

    elsif output =~ /VULNERABLE/
      _log "Vulnerable! #{output.strip}"

      _create_linked_issue("vulnerability_bluekeep", {
        proof: {
          rdpscan: output.strip
        }
      })

    elsif output =~ /UNKNOWN/        
      _log "Unknown! #{output.strip}"
    end

  end

 
end
end
end
