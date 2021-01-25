module Intrigue
module Task
class SearchWayBack < BaseTask
  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "search_wayback_machine",
      :pretty_name => "Search Wayback Machine",
      :authors => ["m-q-t", "mhmdiaa"],
      :description => "Retrieves additional subdomains using Wayback Machine.",
      :references => ["http://web.archive.org/", "https://gist.github.com/mhmdiaa/adf6bff70142e5091792841d4b372050"],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["Domain"],
      :example_entities => [ {"type" => "Domain", "details" => {"name" => "intrigue.io"}} ],
      :allowed_options => [],
      :created_types => ["Domain"]
    }
  end

  def run
    super

    search_string = _get_entity_name

    if search_string =~ /^(http|https):/i
      search_string = URI.parse(search_string).host 
    end

    _log "Getting results for #{search_string} from Wayback Machine"
    json = query_wayback(search_string)

    hosts = []
    json.flatten.each do |record| # flatten 2d array into 1d
      begin
        hosts << URI.parse(record).host
      rescue URI::InvalidURIError
        _log_error "Unable to parse record: #{record}. Skipping."
        next
      end 
    end

    hosts = hosts.uniq # clear out duplicates

    hosts.each do |h|
      unless h.nil? 
        _create_entity "Domain", "name" => "#{h}"
      end
    end
  end

  # Helper function to query thte api 
  def query_wayback(query)
    url = "http://web.archive.org/cdx/search/cdx?url=*.#{query}&output=json&fl=original&collapse=urlkey"
    begin
      response = http_get_body(url)
      json = JSON.parse(response) 
    rescue JSON::ParserError => e
      _log_error "Unable to parse response: #{response}" 
    end
  json
  end

end
end
end