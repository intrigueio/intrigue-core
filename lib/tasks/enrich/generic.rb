module Intrigue
module Task
module Enrich
class Generic < Intrigue::Task::BaseTask

  def self.metadata
    {
      :name => "enrich/generic",
      :pretty_name => "Generic Enrichment",
      :authors => ["jcran"],
      :description => "Ensures the entity is marked enriched. Used when there is no specific enrichment task!",
      :references => [],
      :type => "enrichment",
      :passive => true,
      :allowed_types => ["*"],
      :example_entities => [
        { "type" => "String",
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
  def run
    _log "Marking #{_get_entity_type_string}: #{_get_entity_name} enriched!"
  end

end
end
end
end