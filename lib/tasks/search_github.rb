module Intrigue
class SearchGithub < BaseTask
  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "search_github",
      :pretty_name => "Search Github",
      :authors => ["jcran"],
      :description => "Uses the Github API to search for the existence of a string in repository and user names",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["Organization","String"],
      :example_entities => [
        {"type" => "String", "attributes" => {"name" => "intrigue"}}],
      :allowed_options => [
        {:name => "max_item_count", :type => "Integer", :regex => "integer", :default => 20 },
      ],
      :created_types => ["GithubRepository","GithubUser"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    entity_name = _get_entity_name

    # Search users
    search_uri = "https://api.github.com/search/users?q=#{entity_name}"
    response = _get_response(search_uri)
    _parse_items(response["items"],"GithubUser")

    # Search respositories
    search_uri = "https://api.github.com/search/repositories?q=#{entity_name}"
    response = _get_response(search_uri)
    _parse_items(response["items"],"GithubRepository")

    #search_uri = "https://api.github.com/search/issues?q=#{entity_name}"
    #response = _search_github(search_uri,"GithubIssue")
    #_parse_items response["items"]


  end

  def _get_response(uri)

    begin
      response = JSON.parse(http_get_body(uri))
    rescue JSON::ParserError
      _log "Error retrieving results"
      raise []
    end

    # TODO deal with pagination here
    _log "API responded with #{response["total_count"]} items!"
  response
  end

  def _parse_items(items,type)
    # make sure we don't have too many items


    max_item_count = [items.count,_get_option("max_item_count")].min
    _log "Processing #{max_item_count} #{type} entities"

    # only do 10 items max
    items[0..max_item_count].each do |result|
      _log "Processing #{type}: #{ result["full_name"] || result["login"] }"
      _create_entity type, {
        "name" => result["full_name"] || result["login"],
        "uri" => result["html_url"],
        "raw" => result
      }
    end
  end

end
end
