class Convert  < BaseTask

  def metadata
    {
      :name => "convert_entity",
      :pretty_name => "Convert Entity",
      :authors => ["jcran"],
      :description => "Convert an entity to another type",
      :references => [],
      :allowed_types => ["*"],
      :example_entities => [
        {:type => "String", :attributes => {:name => "intrigue"}}
      ],
      :allowed_options => [
        {:name => "entity_type", :type => "String", :regex => "alpha_numeric", :default => "DnsRecord" },
      ],
      :created_types => ["*"]
    }
  end

  def run
    super

    name = _get_entity_attribute "name"

    _create_entity( _get_option("entity_type"), :name => name )

  end

end
