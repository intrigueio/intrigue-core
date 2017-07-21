module Intrigue
class EmailHarvestTask < BaseTask

  def self.metadata
    {
      :name => "email_harvest",
      :pretty_name => "Email Harvester",
      :authors => ["jcran"],
      :description => "This task scrapes email addresses from search engine results.",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["DnsRecord"],
      :example_entities => [
        {"type" => "DnsRecord", "details" => {"name" => "intrigue.io"}}
      ],
      :allowed_options => [],
      :created_types => ["EmailAddress"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    domain = _get_entity_name

    # Bing
    _log "Scraping Bing for email addresses"
    responses = Client::Search::Bing::SearchScraper.new.search("#{domain}+email")
    email_list = []
    responses.each do |r|
      # Bing auto-bolds these
      r.gsub!("<strong>","")
      r.gsub!("</strong>", "")
      r.scan(/[A-Z0-9]+@#{domain}/i) do |email_address|
        _log_good "Found: #{email_address}"
        _create_entity "EmailAddress", {"name" => "#{email_address}", "comment" => "Scraped via Bing"}
      end
    end

=begin
    # Google
    _log "Scraping Google for email addresses"
    responses = Client::Search::Google::SearchScraper.new.search("@#{domain}+email")
    email_list = []
    responses.each do |r|
      # Google auto-bolds these
      r.gsub!("<b>","")
      r.gsub!("</b>", "")
      r.scan(/[A-Z0-9]+@#{domain}/i) do |email_address|
        _create_entity "EmailAddress", "name" => email_address, "comment" => "Scraped via Google"
      end
    end

=end
  end

end
end
