module Intrigue
module Task
module Enrich
class SnmpService < Intrigue::Task::BaseTask

  def self.metadata
    {
      :name => "enrich/snmp_service",
      :pretty_name => "Enrich SnmpService",
      :authors => ["jcran"],
      :description => "Enrich an SNMP service",
      :references => [],
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
    _log "Enriching... SNMP service: #{_get_entity_name}"
  end

end
end
end
end