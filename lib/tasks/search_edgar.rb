module Intrigue
module Task
class SearchCorpwatch < BaseTask

  def self.metadata
    {
      :name => "search_corpwatch",
      :pretty_name => "Search Corpwatch (EDGAR) Database",
      :authors => ["jcran"],
      :description => "Corpwatch is an intereface to EDGAR. This task allows you to search for US organization data.",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["String", "Organization"],
      :example_entities => [{"type" => "String", "details" => {"name" => "intrigue"}}],
      :allowed_options => [],
      :created_types => ["*"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    # Get the API Key
    api_key = _get_global_config "corpwatch_api_key"

    # Attach to the corpwatch service & search
    x = Client::Search::Corpwatch::ApiClient.new(api_key)
    corps = x.search(_get_entity_name)

    corps.each do |corp|

      # Create a new organization entity & attach a record
      _create_entity "Organization", {
        "name" => corp.name,
        "data" => corp.to_s
      }

      _create_entity "PhysicalLocation", {
        "name" => corp.address,
        "address" => corp.address,
        "state" => corp.state,
        "country" => corp.country
      }

    end
  end
end
end
end
