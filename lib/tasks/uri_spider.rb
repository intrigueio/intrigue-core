require 'arachnid'
require 'uri'

module Intrigue
class UriSpider < BaseTask

  include Intrigue::Task::Web
  include Intrigue::Task::Parse

  def metadata
    {
      :name => "uri_spider",
      :pretty_name => "URI Spider",
      :authors => ["jcran"],
      :description => "This task spiders a given URI, creating entities from the page text, as well as from parsed files.",
      :references => [],
      :allowed_types => ["Uri"],
      :example_entities => [
        {"type" => "Uri", "attributes" => { "name" => "http://www.intrigue.io" }}
      ],
      :allowed_options => [
        {:name => "threads", :type => "Integer", :regex => "integer", :default => 1 },
        {:name => "max_pages", :type => "Integer", :regex => "integer", :default => 1000 },
        {:name => "extract_uris", :type => "Boolean", :regex => "boolean", :default => false },
        {:name => "extract_dns_records", :type => "Boolean", :regex => "boolean", :default => false },
        {:name => "extract_patterns", :type => "String", :regex => "alpha_numeric_list", :default => "*" },
        {:name => "extract_file_metadata", :type => "Boolean", :regex => "boolean", :default => true }
        #{:name => "user_agent",  :type => "String",  :regex => "alpha_numeric", :default => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.111 Safari/537.36"}
      ],
      :created_types =>  ["DnsRecord", "EmailAddress", "File", "Info", "Person", "PhoneNumber", "SoftwarePackage"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    uri = _get_entity_attribute "name"

    # Scanner options
    @opt_threads = _get_option("threads").to_i
    @opt_max_pages = _get_option("max_pages").to_i
    #@opt_user_agent = _get_option "user_agent"
    @opt_extract_uris = _get_option "extract_uris" # create an object for each page
    @opt_extract_dns_records = _get_option "extract_dns_records" # create an object for each dns_record
    @opt_extract_file_metadata = _get_option "extract_file_metadata" # create a Uri object for each page
    @opt_extract_patterns = _get_option("extract_patterns").split(",") # only extract entities withthe following patterns

    crawl_and_extract(uri)

  end # end .run


  def crawl_and_extract(uri)
    @task_result.logger.log "Crawling: #{uri}"
    dns_records = []

    Arachnid.new(uri).crawl({
        :threads => @opt_threads,
        :max_urls => @opt_max_pages}) do |response|

      @task_result.logger.log "Processing #{response.effective_url}"

      # Extract the uri
      page_uri = "#{response.effective_url}"

      # Create an entity for this uri
      _create_entity("Uri", { "name" => page_uri, "uri" => page_uri }) if @opt_extract_uris

      # If we don't have a body, we can't do anything here.
      next unless response.body

      # Extract the body
      page_body = Nokogiri::HTML.parse(response.body.to_s.encode('UTF-8', {
        :invalid => :replace,
        :undef => :replace,
        :replace => '?'})).to_s.encode('UTF-8', {
          :invalid => :replace,
          :undef => :replace,
          :replace => '?'})

      # Create an entity for this host
      if @opt_extract_dns_records

        @task_result.logger.log "Extracting dns records from #{response.effective_url}"
        URI.extract(page_body, ["https","http"]) do |link|
          begin
            # Collect the host
            host = URI(link).host

            # if we have a valid host
            if host

              # check to see if host matches a pattern we'll allow
              pattern_allowed = false
              if @opt_extract_patterns.include? "*"
                pattern_allowed = true
              else
                pattern_allowed = @opt_extract_patterns.select{|x| host =~ /#{x}/ }.count > 0
              end

              # if we got a pass, check to make sure we don't already have it, and add it
              if pattern_allowed
                unless dns_records.include?(host)
                  _create_entity("DnsRecord", "name" => host, "uri" => page_uri)
                  dns_records << host
                end
              end

            end
          rescue URI::InvalidURIError => e
            @task_result.logger.log_error "Unable to parse #{link} from page #{page_uri}"
          end
        end
      end

      if @opt_extract_file_metadata

        # Get the filetype for this page
        filetype = "#{page_uri.split(".").last.gsub("/","")}".upcase

        # A list of all filetypes we're capable of doing something with
        interesting_types = [
          "BIN","DOC","DOCX","EPUB","EXE","ICA","INDD",
          "MP3","MP4","ODG","ODP","ODS","ODT",
          "PDF","PPS","PPSX","PPT","PPTX","PUB",
          "RDP","SVG","SVGZ","SXC","SXI","SXW","TIF",
          "TXT","WPD","XLS","XLSX"]

        if interesting_types.include? filetype
          download_and_extract_metadata page_uri
        else
          parse_entities_from_content(page_uri, page_body)
        end

      else
        @task_result.logger.log "Parsing as a regular file"
        parse_entities_from_content(page_uri, page_body)
      end
    end # end .crawl

  end # crawl_and_extract

end
end
