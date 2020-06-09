module Intrigue
module Task
class UriExtractLinkedHosts  < BaseTask

  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "uri_extract_linked_hosts",
      :pretty_name => "URI Extract Linked Hosts",
      :authors => ["jcran"],
      :description => "This task analyzes and extracts hosts from links.",
      :references => [],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [{"type" => "Uri", "details" => {"name" => "https://intrigue.io"}}],
      :allowed_options => [],
      :created_types => ["DnsRecord"]
    }
  end

  def run
    super


    # Go collect the page's contents
    uri = _get_entity_name
    contents = http_get_body(uri)

    unless contents
      _log_error "Unable to retrieve uri: #{uri}"
      return
    end

    ###
    ### Now, parse out all links and do analysis on the individual links
    ###
    URI.extract(contents, ["https","http"]) do |link|
      begin

        # Collect the host
        host = URI(link).host

        #_create_entity "Uri", "name" => link, "uri" => link
        _create_entity "DnsRecord", "name" => host

      rescue URI::InvalidURIError => e
        _log_error "Error, unable to parse #{link}"
      end
    end

  end

end
end
end
