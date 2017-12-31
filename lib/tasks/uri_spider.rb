module Intrigue
module Task
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
        {:name => "limit", :type => "Integer", :regex => "integer", :default => 100 },
        {:name => "max_depth", :type => "Integer", :regex => "integer", :default => 10 },
        {:name => "spider_whitelist", :type => "String", :regex => "alpha_numeric_list", :default => "(current domain)" },
        {:name => "extract_dns_records", :type => "Boolean", :regex => "boolean", :default => true },
        {:name => "extract_dns_record_pattern", :type => "String", :regex => "alpha_numeric_list", :default => "(current domain)" },
        {:name => "extract_email_addresses", :type => "Boolean", :regex => "boolean", :default => true },
        {:name => "extract_phone_numbers", :type => "Boolean", :regex => "boolean", :default => true },
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
    opt_limit = _get_option "limit"
    opt_max_depth = _get_option "max_depth"
    opt_spider_whitelist = _get_option "spider_whitelist"
    @opt_user_agent = _get_option "user_agent"

    # Parsing options
    @opt_extract_dns_records = _get_option "extract_dns_records"
    @opt_extract_dns_record_pattern = _get_option("extract_dns_record_pattern").split(",") # only extract entities withthe following pattern
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

    # create a default extraction pattern, default to current host
    @opt_extract_dns_record_pattern = ["#{uri.host}"] if @opt_extract_dns_record_pattern == ["(current domain)"]

    # Create a list of whitelist spider regexes from the opt_spider_whitelist options
    whitelist_regexes = opt_spider_whitelist.gsub("(current domain)","#{uri.host}").split(",").map{|x| Regexp.new("#{x}") }

    # Set the spider options. Allow the user to configure a set of regexes we can use to spider
    options = {
      :limit => @opt_limit || 100,
      :max_depth => @opt_max_depth || 10,
      :hosts => [/#{uri.host}/, /#{uri.host.split(".").last(2).join(".")}/].concat(whitelist_regexes)
    }

    crawl_and_extract(uri, options)
  end # end .run


  def crawl_and_extract(uri, options)
    _log "Crawling: #{uri}"
    _log "Options: #{options}"

    dns_records = []

    Spidr.start_at(uri, options) do |spider|

      # Handle redirects
      spider.every_redirect_page do |page|
        next unless page.location
        spider.visit_hosts << page.to_absolute(page.location).host
        spider.enqueue page.to_absolute(page.location)
      end

      # Request every link & check content_type. Parse if interesting
      spider.every_link do |origin,dest|
        if @opt_parse_file_metadata
          response = http_request(:head, "#{dest}")
          next unless response

          content_type = response.content_type
          #_log "Processing link of type: #{content_type} @ #{dest}"

          unless (  content_type == "application/javascript" or
                    content_type == "application/json" or
                    content_type == "application/atom+xml" or
                    content_type == "application/rss+xml" or
                    content_type == "application/x-javascript" or
                    content_type == "application/xml" or
                    content_type == "image/jpeg" or
                    content_type == "image/png" or
                    content_type == "image/svg+xml" or
                    content_type == "image/vnd.microsoft.icon" or
                    content_type == "image/x-icon" or
                    content_type == "text/css" or
                    content_type == "text/html" or
                    content_type == "text/javascript" or
                    content_type == "text/xml"  )
            _log_good "Parsing file of type #{content_type} @ #{dest}"
            download_and_extract_metadata "#{dest}"
          end
        end
      end

      # Parse every page
      spider.every_page do |page|
        _log "Got... #{page.url}"

        if @opt_extract_uris
          _create_entity("Uri", { "name" => "#{page.url}", "uri" => "#{page.url}" })
        end

        # If we don't have a body, we can't do anything here.
        next unless page.body

        # Extract the body
        encoded_page_body = page.body.to_s.encode('UTF-8', {
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
                    _create_entity("DnsRecord", "name" => host, "origin" => page.url)
                    dns_records << host
                  end
                end

              end
            rescue URI::InvalidURIError => e
              _log_error "Unable to parse #{link} from page #{page.url}"
            end
          end
        end

        _log "Parsing as a regular file!"
        parse_phone_numbers_from_content("#{page.url}", encoded_page_body) if @opt_extract_phone_numbers
        parse_email_addresses_from_content("#{page.url}", encoded_page_body) if @opt_extract_email_addresses

        encoded_page_body = nil

      end
    end

  end

end
end
end
