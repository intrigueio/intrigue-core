module Intrigue
class UriSpider < BaseTask

  include Intrigue::Task::Web
  include Intrigue::Task::Parse

  def self.metadata
    {
      :name => "uri_spider",
      :pretty_name => "URI Spider",
      :authors => ["jcran"],
      :description => "This task spiders a given URI, creating entities from the page text, as well as from parsed files.",
      :references => ["http://tika.apache.org/0.9/formats.html"],
      :allowed_types => ["Uri"],
      :type => "discovery",
      :passive => false,
      :example_entities => [
        {"type" => "Uri", "details" => { "name" => "http://www.intrigue.io" }}
      ],
      :allowed_options => [
        {:name => "extract_dns_records", :type => "Boolean", :regex => "boolean", :default => false },
        {:name => "extract_dns_record_pattern", :type => "String", :regex => "alpha_numeric_list", :default => "*" },
        {:name => "extract_email_addresses", :type => "Boolean", :regex => "boolean", :default => false },
        {:name => "extract_phone_numbers", :type => "Boolean", :regex => "boolean", :default => false },
        {:name => "parse_file_metadata", :type => "Boolean", :regex => "boolean", :default => true },
        {:name => "extract_uris", :type => "Boolean", :regex => "boolean", :default => false },
        {:name => "user_agent",  :type => "String",  :regex => "alpha_numeric", :default => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.111 Safari/537.36"}
      ],
      :created_types =>  ["DnsRecord", "EmailAddress", "File", "Info", "Person", "PhoneNumber", "SoftwarePackage"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    uri_string = _get_entity_name

    # Scanner options
    @opt_user_agent = _get_option "user_agent"
    @opt_extract_dns_records = _get_option "extract_dns_records"
    @opt_extract_dns_record_pattern = _get_option("extract_dns_record_pattern").split(",") # only extract entities withthe following patterns
    @opt_extract_email_addresses = _get_option "extract_email_addresses"
    @opt_extract_phone_numbers = _get_option "extract_phone_numbers"
    @opt_extract_uris = _get_option "extract_uris"
    @opt_parse_file_metadata = _get_option "parse_file_metadata" # create a Uri object for each page

    #make sure we have a valid uri
    uri = URI.parse(URI.encode(uri_string))
    unless uri
      _log_error "Unable to parse URI from: #{uri_string}"
      return
    end

    crawl_and_extract(uri)
  end # end .run


  def crawl_and_extract(uri)
    _log "Crawling: #{uri}"
    dns_records = []

    Spidr.site(uri) do |spider|

      # Handle redirects
      spider.every_redirect_page do |page|
        spider.visit_hosts << page.to_absolute(page.location).host
        spider.enqueue page.to_absolute(page.location)
      end

      spider.every_page do |page|
        _log ">>> #{page.url}"

        if @opt_extract_uris
          _create_entity("Uri", { "name" => "#{page.url}", "uri" => "#{page.url}", "spidered" => true })
        end

        # If we don't have a body, we can't do anything here.
        next unless page.body

        # Extract the body
        encoded_page_body = Nokogiri::HTML.parse(page.body.to_s.encode('UTF-8', {
          :invalid => :replace,
          :undef => :replace,
          :replace => '?'})).to_s.encode('UTF-8', {
            :invalid => :replace,
            :undef => :replace,
            :replace => '?'})

        # Create an entity for this host
        if @opt_extract_dns_records

          _log "Extracting DNS records from #{page.url}"
          URI.extract(encoded_page_body, ["https", "http"]) do |link|
            begin
              # Collect the host
              host = URI(link).host

              # if we have a valid host
              if host
                # check to see if host matches a pattern we'll allow
                pattern_allowed = false
                if @opt_extract_dns_record_pattern.include? "*"
                  pattern_allowed = true
                else
                  pattern_allowed = @opt_extract_dns_record_pattern.select{ |x| host =~ /#{x}/ }.count > 0
                end

                # if we got a pass, check to make sure we don't already have it, and add it
                if pattern_allowed
                  unless dns_records.include?(host)
                    _create_entity("DnsRecord", "name" => host, "extracted_from" => page.url)
                    dns_records << host
                  end
                end

              end
            rescue URI::InvalidURIError => e
              _log_error "Unable to parse #{link} from page #{page.url}"
            end
          end
        end

        if @opt_parse_file_metadata

          # Get the filetype for this page
          filetype = "#{page.url.to_s.split(".").last.gsub("/","")}".upcase

          # A list of all filetypes we're capable of doing something with
          interesting_types = [
            "BIN","DOC","DOCX","EPUB","EXE","JPG","JPEG","ICA","INDD",
            "MP3","MP4","ODG","ODP","ODS","ODT","PDF","PPS","PPSX","PPT","PPTX","PUB",
            "RDP","SVG","SVGZ","SXC","SXI","SXW","TIF","TIFF", "TXT","WPD","XLS","XLSX"]

          if interesting_types.include? filetype
            _log_good "interesting file: #{page.url}"
            download_and_extract_metadata "#{page.url}"
          else
            parse_phone_numbers_from_content("#{page.url}", encoded_page_body) if @opt_extract_phone_numbers
            parse_email_addresses_from_content("#{page.url}", encoded_page_body) if @opt_extract_email_addresses
          end

        else
          _log "Parsing as a regular file"
          parse_phone_numbers_from_content("#{page.url}", encoded_page_body) if @opt_extract_phone_numbers
          parse_email_addresses_from_content("#{page.url}", encoded_page_body) if @opt_extract_email_addresses
        end

        encoded_page_body = nil

      end
    end

  end

end
end
