module Intrigue
class CreateEntity < BaseTask

  def self.metadata
    {
      :name => "create_entity",
      :pretty_name => "Create Entity",
      :authors => ["jcran"],
      :description => "This just creates an entity.",
      :references => [],
      :allowed_types => ["*"],
      :example_entities => [
        {"type" => "DnsRecord", "attributes" => {"name" => "intrigue.io"}}
      ],
      :allowed_options => [
        {:name => "depth", :type => "Integer", :regex => "integer", :default => 1 },
      ],
      :created_types => ["*"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    name = _get_entity_attribute("name")
    depth = _get_option("depth").to_i
    type = _get_entity_type

    @task_result.depth = depth
    @task_result.save

    EntityFactory.create_entity_recursive(@project,@task_result,type,{"name" => name})

  end

end
end
