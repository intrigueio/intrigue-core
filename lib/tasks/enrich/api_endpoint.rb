module Intrigue
module Task
module Enrich
class ApiEndpoint < Intrigue::Task::BaseTask

  def self.metadata
    {
      :name => "enrich/api_endpoint",
      :pretty_name => "Enrich ApiEndpoint",
      :authors => ["jcran"],
      :description => "An api endpoint",
      :references => [],
      :allowed_types => ["ApiEndpoint"],
      :type => "enrichment",
      :passive => true,
      :example_entities => [
        {"type" => "ApiEndpoint", "details" => {"name" => "https://intrigue.io"}}],
      :allowed_options => [],
      :created_types => []
    }
  end

  def run

    endpoint = _get_entity_name
    default_response = http_get_body(endpoint)
    _set_entity_detail("default_response", default_response)

  end

end
end
end
end