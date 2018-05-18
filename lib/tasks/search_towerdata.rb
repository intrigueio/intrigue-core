module Intrigue
module Task
class SearchTowerdata < BaseTask

  def self.metadata
    {
      :name => "search_towerdata",
      :pretty_name => "Search Towerdata",
      :authors => ["jcran"],
      :description => "This task hits the Towerdata API and finds info based on an email address.",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["EmailAddress"],
      :example_entities => [{"type" => "EmailAddress", "details" => {"name" => "x@x.com"}}],
      :allowed_options => [],
      :created_types => ["Info"]
    }
  end

  def run
    super

    entity_name = _get_entity_name
    api_key = _get_task_config "towerdata_api_key"

    unless api_key
      _log_error "No api_key?"
      return
    end

    begin
      api = TowerDataApi::Api.new(api_key) # Set API key here
      hash = api.query_by_email(entity_name)
      _create_entity "Info", {
        "name" => "Towerdata details for #{entity_name}",
        "details" => hash }
    rescue Exception => e
      _log_error e.message
    end

  end # end run()

end
end
end
