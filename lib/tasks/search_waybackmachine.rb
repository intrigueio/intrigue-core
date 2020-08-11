module Intrigue
module Task
class SearchWaybackMachine < BaseTask

  def self.metadata
    {
      :name => "search_waybackmachine",
      :pretty_name => "Search Wayback Machine",
      :authors => ["Anas Ben Salah"],
      :description => "This task hits Wayback machine API for extracting subdomains",
      :references => ["https://archive.org/help/wayback_api.php"],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["Domain"],
      :example_entities => [{"type" => "Domain", "details" => {"name" => "intrigue.io"}}],
      :allowed_options => [],
      :created_types => ["DnsRecord"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    entity_name = _get_entity_name
    entity_type = _get_entity_type_string

    if entity_type == "Domain"
      #search for subdomains
      url = "http://web.archive.org/cdx/search/cdx?url=*.#{entity_name}/*&output=json&fl=original&collapse=urlkey"
      response = http_get_body(url)
      puts response
      #json = JSON.parse(response)

      #puts json

    else
      _log_error "Unsupported entity type"
    end

  end #end run

end
end
end
