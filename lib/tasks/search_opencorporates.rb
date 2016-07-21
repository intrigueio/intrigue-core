require 'opencorporates'

module Intrigue
class SearchOpencorporates < BaseTask

  def metadata
    {
      :name => "search_opencorporates",
      :pretty_name => "Search OpenCorporates",
      :authors => ["jcran"],
      :description => "Uses the OpenCorporates API to search for information",
      :references => [],
      :allowed_types => ["*"],
      :example_entities => [
        {"type" => "String", "attributes" => {"name" => "intrigue"}}
      ],
      :allowed_options => [
      ],
      :created_types => ["Organization"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    entity_name = _get_entity_attribute "name"

    o = Opencorporates::Api.new.search entity_name

    o["results"]["companies"].each do |result|
      _create_entity "Organization", {
        :name => result["company"]["name"],
        :uri => result["company"]["opencorporates_url"]
      }
    end


  end

end
end
