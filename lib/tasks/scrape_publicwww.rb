module Intrigue
module Task
class ScrapePublicwww < BaseTask

  include Intrigue::Task::Web
  include Intrigue::Task::Browser

  def self.metadata
    {
      :name => "scrape_publicwww",
      :pretty_name => "Scrape PublicWWW",
      :authors => ["jcran"],
      :description => "This searches the PublicWWW api for new subdomains.",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["Domain","DnsRecord"],
      :example_entities => [
        {"type" => "DnsRecord", "details" => {"name" => "intrigue.io"}}
      ],
      :allowed_options => [
        {:name => "pages", :regex=> "integer", :default => 5 },
        {:name => "sleep_max", :regex=> "integer", :default => 10 },
      ],
      :created_types => ["DnsRecord"]
    }
  end

  ## This is hacky, build a module for the API soon.
  def run
    super

    max_page_count = _get_option "pages"
    domain_name = _get_entity_name

    max_page_count.times do |page_count|

      # Get a page
      uri = "https://publicwww.com/websites/%22.#{domain_name}%22/#{page_count + 1}"
      session = create_browser_session
      body_text = capture_document(session,uri)[:contents]
      _log "Got text: #{body_text}"

      body_text.gsub("<\/?b>","").scan(/[a-z0-9\.\-_]+\.#{domain_name}/).each do |d|
        _log_good "Got: #{d}"
        if d =~ /__/ || d =~ /\*\*/
          _log "Skipping #{d}, looks obfu'd"
          next
        end
        _create_entity "DnsRecord", "name" => d
      end

      # Sleep randomly
      sleep_max = _get_option("sleep_max")
      sleep rand(sleep_max)

    end

  end

end
end
end
