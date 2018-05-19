
module Intrigue
module Task
class EnrichSnmp < BaseTask

  def self.metadata
    {
      :name => "enrich/snmp_service",
      :pretty_name => "Enrich SNMP Service",
      :authors => ["jcran"],
      :description => "This task connects to a snmp service and pulls out system details.",
      :references => ["https://community.rapid7.com/community/services/blog/2016/05/05/snmp-data-harvesting-during-penetration-testing"],
      :type => "enrichment",
      :passive => false,
      :allowed_types => ["SnmpService"],
      :example_entities => [
        { "type" => "SnmpService",
          "details" => {
            "ip_address" => "1.1.1.1",
            "port" => 161,
            "protocol" => "udp"
          }
        }
      ],
      :allowed_options => [],
      :created_types => []
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    port = _get_entity_detail("port").to_i || 161
    protocol = _get_entity_detail "protocol" || "udp"
    ip_address = _get_entity_detail "ip_address"

    _log "Port: #{port}"
    _log "Protocol: #{protocol}"
    _log "IP Address: #{ip_address}"

    # Check to make sure we have a sane target
    if ip_address && port

      # SNMPwalk
      begin
        output = ""
        SNMP::Manager.open(:host => ip_address, :port => port) do |manager|
          ifTable = SNMP::ObjectId.new("1.")
          next_oid = ifTable
          while next_oid.subtree_of?(ifTable)
              response = manager.get_next(next_oid)
              varbind = response.varbind_list.first
              next_oid = varbind.name
              _log "#{varbind}"
              output << varbind.to_s
          end
        end
        _set_entity_detail("snmp_output", _encode_string(output))
      rescue SNMP::RequestTimeout => e
        _log_error "SNMP Timeout"
      end

    else
      raise ArgumentError, "Missing IP Address and Port. Unable to open a socket."
    end

    _finalize_enrichment
  end

end
end
end
