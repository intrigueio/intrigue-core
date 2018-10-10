module Intrigue
module Enrich
class Organization < BaseTask

  def self.metadata
    {
      :name => "enrich/organization",
      :pretty_name => "Enrich Organization",
      :authors => ["jcran"],
      :description => "Fills in details for an Organization",
      :references => [],
      :type => "enrichment",
      :passive => false,
      :allowed_types => ["Organization"],
      :example_entities => [
        { "type" => "Organization",
          "details" => {
            "name" => "Intrigue.io"
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

    _log "Enriching... organization #{_get_entity_name}"
  end

end
end
end
