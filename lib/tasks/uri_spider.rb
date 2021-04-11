module Intrigue
module Task
class UriSpider < BaseTask

  def self.metadata
    {
      :name => "uri_spider",
      :pretty_name => "URI Spider",
      :authors => ["jcran"],
      :description => "This task spiders a given URI, creating entities from the page text, as well as from parsed files.",
      :references => ["http://tika.apache.org/1.22/formats.html"],
      :allowed_types => ["Uri"],
      :type => "discovery",
      :passive => false,
      :example_entities => [
        {"type" => "Uri", "details" => { "name" => "http://www.intrigue.io" }}
      ],
      :allowed_options => [
        {:name => "spider_user_agent", :regex => "alpha_numeric", :default => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.111 Safari/537.36"},
        {:name => "spider_limit", :regex => "integer", :default => 40 },
        {:name => "spider_max_depth", :regex => "integer", :default => 3 },
        {:name => "spider_whitelist", :regex => "alpha_numeric_list", :default => "(current domain)" },
        {:name => "extract_dns_records", :regex => "boolean", :default => true },
        {:name => "extract_dns_record_pattern", :regex => "alpha_numeric_list", :default => "(current domain)" },
        {:name => "extract_email_addresses", :regex => "boolean", :default => false },
        {:name => "extract_phone_numbers", :regex => "boolean", :default => false },
        {:name => "parse_file_metadata", :regex => "boolean", :default => false },
        {:name => "extract_uris", :regex => "boolean", :default => false }
      ],
      :created_types =>  ["DnsRecord", "EmailAddress", "File",
       "CreditCard", "Person", "PhoneNumber", "SoftwarePackage"],
      :queue => "task_spider"
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    uri_string = _get_entity_name

    # Spider options
    @opt_limit = _get_option("spider_limit").to_i
    @opt_max_depth = _get_option("spider_max_depth").to_i
    @opt_spider_whitelist = _get_option "spider_whitelist"
    @opt_user_agent = _get_option "spider_user_agent"

    # Parsing options
    @opt_extract_dns_records = _get_option "extract_dns_records"
    @opt_extract_dns_record_pattern = _get_option("extract_dns_record_pattern").split(",") # only extract entities withthe following pattern
    @opt_extract_email_addresses = _get_option "extract_email_addresses"
    @opt_extract_phone_numbers = _get_option "extract_phone_numbers"
    @opt_extract_uris = _get_option "extract_uris"
    @opt_parse_file_metadata = _get_option "parse_file_metadata" # create a Uri object for each page

    # Make sure we have a valid uri
    uri = URI.parse(URI.encode(uri_string))
    unless uri
      _log_error "Unable to parse URI from: #{uri_string}"
      return
    end

    # create a default extraction pattern, default to current domain
    if @opt_extract_dns_record_pattern == ["(current domain)"]
      @opt_extract_dns_record_pattern = [parse_domain_name("#{uri.host}")]
    end

    # Create a list of whitelist spider regexes from the opt_spider_whitelist options
    whitelist_regexes = @opt_spider_whitelist.gsub("(current domain)",
      "#{uri.host}").split(",").map{|x| Regexp.new("#{x}") }

    # Set the spider options. Allow the user to configure a set of regexes we can use to spider
    # :open_timeout (Integer) Optional open timeout.
    # :read_timeout (Integer) Optional read timeout.
    # :ssl_timeout (Integer) Optional ssl timeout.
    # :continue_timeout (Integer) Optional continue timeout.
    # :keep_alive_timeout (Integer) Optional keep_alive timeout.
    options = {
      :limit => @opt_limit,
      :max_depth => @opt_max_depth,
      :open_timeout => 5,
      :read_timeout => 5,
      :ssl_timeout => 5,
      :continue_timeout => 5,
      :keep_alive_timeout => 5,
      :hosts => [/#{uri.host}/].concat(whitelist_regexes).uniq
    }

    crawl_and_extract(uri, options)
  end # end .run

  def crawl_and_extract(uri, options)
    _log "Crawling: #{uri}"
    _log "Options: #{options}"

    dns_records = []
    crawled_pages = []

    Spidr.start_at(uri, options) do |spider|

      begin
        # spider each page
        spider.every_page do |page|

          next if crawled_pages.include? page.url

          next unless "#{page.url}".length > 3

          crawled_pages << page.url

          # If we don't have a body, we can't do anything here.
          next unless page.body

          # Extract the body (removing unknown unicode characters)
          encoded_page_body = "#{page.body}".sanitize_unicode

          # Create an entity for this host
          if @opt_extract_dns_records

            _log "Extracting DNS records from #{page.url}"
            URI.extract(encoded_page_body, ["https", "http", "ftp"]).uniq do |link|

              # Collect the host
              begin
                hostname = URI(link).host
              rescue URI::InvalidURIError => e
                next
              end

              # skip anythin nil
              next unless hostname

              # check to see if host matches a pattern we'll allow
              pattern_allowed = false
              if @opt_extract_dns_record_pattern.include? "*"
                pattern_allowed = true
              else
                pattern_allowed = @opt_extract_dns_record_pattern.find{ |x| hostname =~ /#{x}/ }
              end

              # if we got a pass, check to make sure we don't already have it, and add it
              create_dns_entity_from_string("#{hostname}") if pattern_allowed

            end # end dns records
          end

          if @opt_parse_file_metadata
            content_type = "#{page.content_type}".split(";").first

            ignore_types = [
              "application/javascript", "text/xml", "application/atom+xml",
              "application/rss+xml", "application/x-javascript", "application/xml",
              "image/jpeg", "image/png", "image/svg+xml", "image/vnd.microsoft.icon",
              "image/x-icon", "text/css", "text/html", "text/javascript", "text/plain" ]

            unless ignore_types.include? content_type
              _log_good "Parsing document of type #{content_type} @ #{page.url}"
              metadata = download_and_extract_metadata "#{page.url}"
              _set_entity_detail("extended_metadata",metadata)
            end

          end

          # add phone numbers and email addresses if we were requested to do so
          parse_phone_numbers_from_content("#{page.url}", encoded_page_body) if @opt_extract_phone_numbers
          parse_email_addresses_from_content("#{page.url}", encoded_page_body) if @opt_extract_email_addresses

          # add the uri if we were requested to do so
          _create_entity("Uri", { "name" => "#{page.url}", "uri" => "#{page.url}" }) if @opt_extract_uris

          encoded_page_body = nil

        end # end every page

      rescue URI::InvalidURIError => e
        _log_error "#{e} ... #{page.url}"
      end # end begin

    end # end start_at

    _set_entity_detail "extended_spider", crawled_pages

  end

end
end
end
