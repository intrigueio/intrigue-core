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
        {:name => "extract_pattern", :regex => "alpha_numeric", :default => false },
      ],
      :created_types => ["DnsRecord"]
    }
  end

  def run
    super

    search_domain = _get_entity_name

    # default to our name for the extract pattern
    if _get_option("extract_pattern") != "false"
      opt_extract_pattern = _get_option("extract_pattern")
    else
      opt_extract_pattern = search_domain
    end

    begin

      # gather all related certs
      crt_query_uri = "https://crt.sh/?q=%25.#{search_domain}"
      html = Nokogiri::HTML(http_get_body(crt_query_uri))
      cert_ids = html.xpath("//td/a/@href").map do |x|
        x.to_s.gsub("\n","").strip
      end

      # individually query certs
      cert_ids.each do |cert_id|
        
        scrape_uri = "https://crt.sh/#{cert_id}&opt=nometadata"
        raw_html = http_get_body(scrape_uri)

        # if we didn't get anything, wait a bit
        unless raw_html
          _log_error "Error getting #{scrape_uri}"
          sleep rand(10)
          next
        end

        # scrape
        raw_html.scan(/DNS:(.*?)<BR>/).each do |domains|
          domains.each do |dname|

            # respect our extract pattern
            unless dname =~ /#{opt_extract_pattern}/
              _log "Skipping #{dname} - doesnt match our extract pattern"
              next
            end

            # Remove any leading wildcards
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
