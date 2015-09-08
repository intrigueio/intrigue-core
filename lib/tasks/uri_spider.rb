require 'arachnid'

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
        {:name => "threads", :type => "Integer", :regex => "integer", :default => 4 },
        {:name => "max_pages", :type => "Integer", :regex => "integer", :default => 250 },
        {:name => "create_urls", :type => "Boolean", :regex => "boolean", :default => false },
        {:name => "parse_metadata", :type => "Boolean", :regex => "boolean", :default => true }
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
    @opt_create_urls = _get_option "create_urls" # create a Uri object for each page
    @opt_parse_metadata = _get_option "parse_metadata" # create a Uri object for each page

    crawl_and_parse(uri)

  end # end .run


  def crawl_and_parse(uri)
    @task_log.log "Crawling: #{uri}"

    Arachnid.new(uri, {
        :exclude_urls_with_images => true }).crawl({
          :threads => @opt_threads,
          :max_urls => @opt_max_pages}) do |response|

        begin

          # Extract the url
          page_uri = "#{response.effective_url}".encode('UTF-8', {
            :invalid => :replace,
            :undef => :replace,
            :replace => '?'})

          # Create an entity for this uri
          _create_entity("Uri", { "name" => page_uri, "uri" => page_uri }) if @opt_create_urls

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

          if @opt_parse_metadata

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
            @task_log.log "Parsing as a regular file"
            parse_entities_from_content(page_uri, page_body)
          end

        end

    end # end .crawl
  end # crawl_and_parse

end
end
