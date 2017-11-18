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
        {:name => "extract_pattern", :type => "String", :regex => "alpha_numeric", :default => false },
        {:name => "gather_subdomains", :type => "Boolean", :regex => "boolean", :default => true }
      ],
      :created_types => ["DnsRecord"]
    }
  end

  def run
    super

    search_domain = _get_entity_name
    opt_gather_subdomains = _get_option "gather_subdomains"
    opt_extract_pattern = _get_option("extract_pattern") == "false"

    if opt_gather_subdomains
      crt_query_uri = "https://crt.sh/?q=#{search_domain}"
      begin

        # gather all related certs
        html = Nokogiri::HTML(http_get_body(crt_query_uri))
        cert_ids = html.xpath("//td/a/@href").map do |x|
          x.to_s.gsub("\n","").strip
        end

        # individually query certs
        cert_ids.each do |cert_id|
          crt_cert_uri = "https://crt.sh/"
          raw_html = http_get_body("#{crt_cert_uri}#{cert_id}&opt=nometadata")

          # run and hide
          if (
               raw_html =~ /acquia/i              ||
               raw_html =~ /cloudflare/i          ||
               raw_html =~ /distil/i              ||
               raw_html =~ /fastly/i              ||
               raw_html =~ /incapsula.com/i       ||
               raw_html =~ /imperva/i             ||
               raw_html =~ /jive/i                ||
               raw_html =~ /lithium/i             ||
               raw_html =~ /wpengine/i            ||
               raw_html =~ /cdnetworks.com/i)
            _log_error "Invalid keyword in response, failing."
            return
          end

          raw_html.scan(/DNS:(.*?)<BR>/).each do |domains|
            domains.each do |dname|
              _log "Found domain: #{dname}"

              if (dname =~ /cloudflare.net/i || /incapsula.com/i)
                _log_error "Invalid certificate found: #{dname}"
                return nil
              end

              # If we have an extract pattern set, respect it
              if opt_extract_pattern
                next unless dname =~ /#{opt_extract_pattern}/
              end

              # Remove any leading wildcards so we get a sensible domain name
              if dname[0..1] == "*."
                dname = dname[2..-1]
              end

              _create_entity("DnsRecord", "name"=> dname )
            end
          end

        end
      rescue StandardError => e
        _log_error "Error grabbing crt domains: #{e}"
      end
    end

  end

end
end
end
