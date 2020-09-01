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
    resp = http_request(:get, endpoint)

    hash=nil
    begin # live life on the wild side
      hash = JSON.parse(resp.body)
      is_json = true
    rescue JSON::ParserError => e 
      is_json = false
      # no parse :[
    end

    _set_entity_detail("response", hash || resp.body )
    _set_entity_detail("code", resp.code)
    _set_entity_detail("is_json", is_json)
  end

end
end
end
end