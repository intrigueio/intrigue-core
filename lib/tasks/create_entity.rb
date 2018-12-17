module Intrigue
module Task
class CreateEntity < BaseTask

  def self.metadata
    {
      :name => "create_entity",
      :pretty_name => "Create Entity",
      :authors => ["jcran"],
      :description => "This task simply creates an entity.",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["*"],
      :example_entities => [
        {"type" => "DnsRecord", "details" => {"name" => "intrigue.io"}}
      ],
      :allowed_options => [],
      :created_types => ["*"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    name = _get_entity_name
    type = _get_entity_type_string
    e = _create_entity type, {"name" => name }
  end

end
end
end
