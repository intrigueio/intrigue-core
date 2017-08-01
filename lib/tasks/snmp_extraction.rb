require 'snmp'

module Intrigue
class SnmpExtraction < BaseTask

  def self.metadata
    {
      :name => "snmp_extraction",
      :pretty_name => "SNMP Extraction",
      :authors => ["jcran"],
      :description => "This task connects to a snmp service and pulls out system details.",
      :references => ["https://community.rapid7.com/community/services/blog/2016/05/05/snmp-data-harvesting-during-penetration-testing"],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["SnmpServer"],
      :example_entities => [
        {"type" => "SnmpServer", "details" => {
          "ip_address" => "1.1.1.1",
          "port" => 161,
          "protocol" => "udp"
          }
        }
      ],
      :allowed_options => [ ],
      :created_types => []
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    # XXX - how to deal with accepting a complex object like this through
    # the UI? We'd need to know the entity structure, or set these up as options?

    port = _get_entity_attribute("port").to_i || 161
    protocol = _get_entity_attribute "proto"
    ip_address = _get_entity_attribute "ip_address"

    _log "Port: #{port}"
    _log "Protocol: #{protocol}"
    _log "IP Address: #{ip_address}"

    # Check to make sure we have a sane target
    if ip_address && port

      # SNMPwalk
      begin
        output = ""
        SNMP::Manager.open(:host => ip_address) do |manager|
          ifTable = SNMP::ObjectId.new("1.")
          next_oid = ifTable
          while next_oid.subtree_of?(ifTable)
              response = manager.get_next(next_oid)
              varbind = response.varbind_list.first
              next_oid = varbind.name
              _log varbind.to_s
              output << varbind.to_s
          end
        end

        @entity.set_detail("snmp_output", _encode_string(output))

      end

    else
      raise ArgumentError, "Missing IP Address and Port. Unable to open a socket."
    end

  end

end
end
