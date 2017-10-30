module Intrigue
module Task
class SearchBuiltwith < BaseTask

  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "search_builtwith",
      :pretty_name => "Search BuiltWith",
      :authors => ["jcran"],
      :description => "This task hits the Builtwith Free API and enriches a domain",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["DnsRecord"],
      :example_entities => [{"type" => "String", "details" => {"name" => "intrigue.io"}}],
      :allowed_options => [],
      :created_types => []
    }
  end

  ## Default method, subclasses must override this
  def run
    super

      # Make sure the key is set
      api_key = _get_global_config "builtwith_api_key"
      entity_name = _get_entity_name

      unless api_key
        _log_error "No credentials?"
        return
      end

      # Attach to the builtwith service & search
      begin
        response = http_get_body("https://api.builtwith.com/v12/api.json?KEY=#{api_key}&LOOKUP=#{entity_name}")
        json = JSON.parse(response)
        json["Results"].each do |result|
          result["Result"]["Paths"].each do |path|
            path["Technologies"].each do |tech|
              _log_good "#{path["Url"]}: #{tech["Name"]}: #{tech["Description"]} (#{tech["Link"]})"
            end
          end
        end
      rescue JSON::ParserError => e
        _log_error "Error parsing: #{e}"
      end

  end # end run()

end # end Class
end
end
