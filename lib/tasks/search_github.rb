module Intrigue
module Task
class SearchGithub < BaseTask

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
        {"type" => "String", "details" => {"name" => "intrigue"}}],
      :allowed_options => [],
      :created_types => ["GithubRepository","GithubAccount"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    entity_name = _get_entity_name

    # Search users
    search_uri = "https://api.github.com/search/users?q=#{entity_name}"
    response = _get_github_response(search_uri)
    # Create
    response["items"].each do |result|
      _create_entity "GithubAccount", {
        "name" => result["login"],
        "uri" => result["html_url"],
        "account_type" => result["type"],
        "raw" => result
      }
    end

    # Search repositories
    search_uri = "https://api.github.com/search/repositories?q=#{entity_name}"
    response = _get_response(search_uri)
    # Create
    response["items"].each do |result|
      _create_entity "GithubRepository", {
        "name" => result["full_name"],
        "uri" => result["html_url"],
        "raw" => result
      }
    end

    # grab the users from the repo strings
    response["items"].each do |result|
      _create_entity "GithubAccount", {
        "name" => result["owner"]["login"],
        "uri" => result["owner"]["html_url"],
        "account_type" => result["owner"]["type"],
        "raw" => result["owner"]
      }
    end

    # Issues
    #search_uri = "https://api.github.com/search/issues?q=#{entity_name}"
    #response = _search_github(search_uri,"GithubIssue")
    #_parse_items response["items"]


  end

  def _get_github_response(uri)

    begin
      response = JSON.parse(http_get_body(uri))
    rescue JSON::ParserError
      _log "Error retrieving results"
      response = []
    end

    # TODO deal with pagination here
    _log "API responded with #{response["total_count"]} items!"
  response
  end

end
end
end
