module Intrigue
module Enrich
class NetworkService < BaseTask

  def self.metadata
    {
      :name => "enrich/network_service",
      :pretty_name => "Enrich Network Service",
      :authors => ["jcran"],
      :description => "Fills in details for a Network Service",
      :references => [],
      :type => "enrichment",
      :passive => false,
      :allowed_types => ["NetworkService"],
      :example_entities => [
        { "type" => "NetworkService",
          "details" => {
            "ip_address" => "1.1.1.1",
            "port" => 1111,
            "protocol" => "tcp"
          }
        }
      ],
      :allowed_options => [],
      :created_types => []
    }
  end

  ## Default method, subclasses must override this
  def self.run(entity, task_result)
    @entity = entity
    @task_result = task_result

    _log "Enriching... nework_service #{_get_entity_name}"
  end

end
end
end
