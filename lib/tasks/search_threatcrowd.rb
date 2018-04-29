module Intrigue
module Task
class SearchThreatcrowd < BaseTask
  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "search_threatcrowd",
      :pretty_name => "Search ThreatCrowd",
      :authors => ["jcran"],
      :description => "This task hits the ThreatCrowd API and finds related content. Discovered IPs / subdomains / emails are created.",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["DnsRecord"],
      :example_entities => [{"type" => "DnsRecord", "details" => {"name" => "intrigue.io"}}],
      :allowed_options => [
        {:name => "extract_pattern", :regex => "alpha_numeric", :default => false },
        {:name => "gather_resolutions", :regex => "boolean", :default => true },
        {:name => "gather_subdomains", :regex => "boolean", :default => true },
        {:name => "gather_email_addresses", :regex => "boolean", :default => true }
      ],
      :created_types => ["DnsRecord", "EmailAddress", "IpAddress"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    opt_gather_email_addresses = _get_option "gather_email_addresses"
    opt_extract_pattern = _get_option("extract_pattern") == "false"
    opt_gather_resolutions = _get_option "gather_resolutions"
    opt_gather_subdomains = _get_option "gather_subdomains"

    # Check Sublist3r API & create domains from returned JSON
    search_domain = _get_entity_name
    search_uri = "https://www.threatcrowd.org/searchApi/v2/domain/report/?domain=#{search_domain}"
    begin
      tc_json = JSON.parse(http_get_body(search_uri))

      if tc_json["response_code"] == "1"

        # handle IP resolution
        if opt_gather_resolutions
          _log "Gathering Resolutions"
          tc_json["resolutions"].each do |res|
            _create_entity "IpAddress", {
              "name" => res["ip_address"],
              "resolver" => "threatcrowd",
              "last_resolved" => res["last_resolved"]
              } unless res["ip_address"] == "-" || res["ip_address"].length < 8
          end
        end

        # Handle Subdomains
        if opt_gather_subdomains
          _log "Gathering Subdomains"
          tc_json["subdomains"].each do |d|

            # If we have an extract pattern set, respect it
            if opt_extract_pattern.kind_of? String
              _log "Checking pattern: #{opt_extract_pattern} vs #{d}"
              next unless d =~ /#{opt_extract_pattern}/
            end

            # seems like this needs some cleanup?
            d.gsub!(":","")
            d.gsub!(" ","")
            d.gsub!("*.","")
           if d.length > 0
             _create_entity "DnsRecord", { "name" => d }
           else
             _log "Skipping empty entry"
           end
          end
        end

        # Handle Emails
        if opt_gather_email_addresses
          _log "Gathering Email Addresses"
          tc_json["emails"].each do |e|

            # If we have an extract pattern set, respect it
            if opt_extract_pattern
              _log "Checking pattern: #{opt_extract_pattern} vs #{e}"
              next unless e =~ /#{opt_extract_pattern}/
            end

            _create_entity "EmailAddress", { "name" => e } unless e == ""
          end
        end

      else
        _log_error "Got error code: #{tc_json["response_code"]}"
      end

    rescue JSON::ParserError => e
      _log_error "Unable to get parsable response from #{search_uri}: #{e}"
    rescue StandardError => e
      _log_error "Error grabbing threatcrowd domains: #{e}"
    end



  end # end run()

end # end Class
end
end
