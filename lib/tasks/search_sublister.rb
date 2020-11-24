module Intrigue
module Task
class SearchSublister < BaseTask
  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "search_sublister",
      :pretty_name => "Search Sublist3r",
      :authors => ["jcran"],
      :description => "This task hits Sublis3r's API for subdomains and creates new DnsRecord entities.",
      :references => ["https://github.com/aboul3la/Sublist3r/"],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["Domain","DnsRecord"],
      :example_entities => [ {"type" => "DnsRecord", "details" => {"name" => "intrigue.io"}} ],
      :allowed_options => [
        {:name => "extract_pattern", :regex => "alpha_numeric", :default => false }
      ],
      :created_types => ["DnsRecord"]
    }
  end

  def run
    super

    opt_extract_pattern = _get_option("extract_pattern") == "false"

    # Check Sublist3r API & create domains from returned JSON
    search_domain = _get_entity_name
    search_uri = "https://api.sublist3r.com/search.php?domain=#{search_domain}"
    begin

      response = http_get_body(search_uri)

      unless response
        _log_error "No response"
        return
      end

      sublister_domains = JSON.parse(response)
      _log_good "Got sublister domains: #{sublister_domains}"
      sublister_domains.each do |d|

        # If we have an extract pattern set, respect it
        if opt_extract_pattern
          next unless d =~ /#{opt_extract_pattern}/
        end

        _create_entity("DnsRecord", {"name" => "#{d}"})

      end
    rescue JSON::ParserError => e
      _log_error "Unable to get parsable response from #{search_uri}: #{e}"
    rescue StandardError => e
      _log_error "Error grabbing sublister domains: #{e}"
    end

  end

end
end
end
