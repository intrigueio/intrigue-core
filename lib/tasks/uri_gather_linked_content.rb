module Intrigue
module Task
class UriGatherLinkedContent  < BaseTask

  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "uri_gather_linked_content",
      :pretty_name => "URI Gather Linked Content",
      :authors => ["jcran"],
      :description => "This task analyzes and extracts links.",
      :references => [],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [{"type" => "Uri", "details" => {"name" => "https://intrigue.io"}}],
      :allowed_options => [],
      :created_types => ["DnsRecord","Uri"]
    }
  end

  def run
    super


    # Go collect the page's contents
    uri = _get_entity_name
    contents = http_get_body(uri)

    return _log_error "Unable to retrieve uri: #{uri}" unless contents

    ###
    ### Now, parse out all links and do analysis on the individual links
    ###
    original_dns_records = []
    URI.extract(contents, ["https","http"]) do |link|
      begin

        # Collect the host
        host = URI(link).host

        _create_entity "Uri", "name" => link, "uri" => link
        _create_entity "DnsRecord", "name" => host

        # Add to both arrays, so we can keep track of the original set, and a resolved set
        original_dns_records << host

      rescue URI::InvalidURIError => e
        _log_error "Error, unable to parse #{link}"
      end
    end

  end

end
end
end
