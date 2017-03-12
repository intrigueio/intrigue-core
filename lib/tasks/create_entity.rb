module Intrigue
class CreateEntity < BaseTask

  def self.metadata
    {
      :name => "create_entity",
      :pretty_name => "Create Entity",
      :authors => ["jcran"],
      :description => "This just creates an entity.",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["*"],
      :example_entities => [
        {"type" => "Host", "attributes" => {"name" => "intrigue.io"}}
      ],
      :allowed_options => [
        #{:name => "depth", :type => "Integer", :regex => "integer", :default => 1 },
      ],
      :created_types => ["*"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    name = _get_entity_name
    type = _get_entity_type

    _create_entity type, {"name" => name }
  end

end
end
