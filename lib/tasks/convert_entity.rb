module Intrigue
module Task
class ConvertEntity < BaseTask

  def self.metadata
    {
      :name => "convert_entity",
      :pretty_name => "Convert Entity",
      :authors => ["jcran"],
      :description => "Convert an entity to another type",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["*"],
      :example_entities => [
        {"type" => "String", "details" => {"name" => "intrigue"}}
      ],
      :allowed_options => [
        {:name => "convert_to_type", :type => "String", :regex => "alpha_numeric", :default => "String" },
      ],
      :created_types => ["*"]
    }
  end

  def run
    super
    name = _get_entity_name
    _create_entity( _get_option("convert_to_type"), "name" => name )
  end

end
end
end
