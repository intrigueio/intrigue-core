module Intrigue
module Task
class SearchCrt < BaseTask
  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "search_crt",
      :pretty_name => "Search CRT",
      :authors => ["jcran"],
      :description => "This task hit CRT's API and creates new DnsRecord entities.",
      :references => ["https://www.virustotal.com/en/documentation/"],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["DnsRecord"],
      :example_entities => [ {"type" => "DnsRecord", "details" => {"name" => "intrigue.io"}} ],
      :allowed_options => [
        {:name => "extract_pattern", :regex => "alpha_numeric", :default => "default" },
      ],
      :created_types => ["DnsRecord"]
    }
  end

  def run
    super

    search_domain = _get_entity_name

    # default to our name for the extract pattern
    if _get_option("extract_pattern") != "default"
      opt_extract_pattern = _get_option("extract_pattern")
    else
      opt_extract_pattern = search_domain
    end

    begin

      # Grab the ATOM feed
      not_to_exceed = 0
      crt_query_uri = "https://crt.sh/atom?q=%25.#{search_domain}"
      raw_html = http_get_large_body(crt_query_uri)

      # if we don't get it, loop until we do
      until raw_html || not_to_exceed == 10
        _log_error "Error getting #{crt_query_uri}, trying again"
        backoff = rand(20) * not_to_exceed # slowly backoff
        _log "Waiting #{backoff} seconds"
        sleep backoff
        # try again
        raw_html = http_get_large_body(crt_query_uri)
        not_to_exceed +=1
      end

      # Parse it
      subdomains = raw_html.scan(/<summary type="html">(.*?)\.#{search_domain}[&<\ ]/)
      _log "No matching domains found" if subdomains.count == 0

      subdomains.each do |d|
        domain = d.first
        _log "Got domain: #{domain}.#{search_domain}"

        # Remove any leading wildcards
        if domain[0..1] == "*."
          domain = domain[2..-1]
        end

        # check for sanity
        unless "#{domain}.#{search_domain}" =~ /#{opt_extract_pattern}/
          _log "Unable to create #{domain}.#{search_domain}, doesnt match #{opt_extract_pattern}"
          next
        end

        # woot
        _create_entity("DnsRecord", "name"=> "#{domain}.#{search_domain}" )
      end

    rescue StandardError => e
      _log_error "Error grabbing crt domains: #{e}"
    end

  end

  def http_get_large_body(uri)
    r = http_request(:get, uri, nil, {}, nil,240,240,240)
  r.body if r
  end

end
end
end
