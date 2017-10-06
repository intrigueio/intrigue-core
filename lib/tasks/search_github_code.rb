module Intrigue
module Task
class SearchGithubCode < BaseTask
  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "search_github_code",
      :pretty_name => "Search Github Code",
      :authors => ["jcran"],
      :description => "Uses the Github API to search repositories for keywords",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["GithubUser","GithubRepository"],
      :example_entities => [
        {"type" => "GithubUser", "details" => {"name" => "intrigueio"}}],
      :allowed_options => [
        {:name => "keywords", :type => "String", :regex => "alpha_numeric", :default => "password" },
        {:name => "max_item_count", :type => "Integer", :regex => "integer", :default => 5 },
      ],
      :created_types => ["Info"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    entity_name = _get_entity_name
    entity_type = _get_entity_type_string
    keywords = _get_option "keywords"

    keywords.split(",").each do |keyword|
      # Search users
      if entity_type == "GithubUser"
        search_uri = "https://api.github.com/search/code?q=#{keyword} user:#{entity_name}"
      elsif entity_type == "GithubRepository"
        search_uri = "https://api.github.com/search/code?q=#{keyword} repo:#{entity_name}"
      end

      response = _get_json_response(search_uri)
      items = response["items"]
      return unless items

      max_item_count = [items.count,_get_option("max_item_count")].min

      _log "Processing #{max_item_count} results"

      # only do 10 items max
      items[0..max_item_count].each do |result|
        #_log "Processing #{result}"
        _create_entity "Info", {
          "name" => result["path"],
          "uri" => result["html_url"],
          "raw" => result
        }
      end
    end
  end

  def _get_json_response(uri)

    begin
      response = JSON.parse(http_get_body(uri))
    rescue JSON::ParserError
      _log "Error retrieving results"
      return []
    end

    # TODO deal with pagination here

    _log "API responded with #{response["total_count"]} items!"

  response
  end

end
end
end
