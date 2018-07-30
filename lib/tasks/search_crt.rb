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
        sleep rand(60)
        raw_html = http_get_large_body(crt_query_uri)
        not_to_exceed +=1
      end

      # Parse it
      subdomains = raw_html.scan(/<summary type="html">(.*?)\.#{search_domain}[&<\ ]/)

      if x.count == 0
        _log "No matching domains found"
        return
      end

      subdomains.each do |d|
        domain = d.first
        _log "got domain: #{domain}.#{search_domain}"

        # Remove any leading wildcards
        if domain[0..1] == "*."
          domain = domain[2..-1]
        end

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
