require 'anemone'
module Intrigue
class UriSpiderAndGatherMetadataTask < BaseTask

  include Intrigue::Task::Web
  include Intrigue::Task::Parse

  def metadata
    {
      :name => "uri_spider_and_gather_metadata",
      :pretty_name => "URI Spider and Gather Metadata",
      :authors => ["jcran"],
      :description => "This task spiders a given URI, creating entities from the page text, as well as from parsed files.",
      :references => [],
      :allowed_types => ["Uri"],
      :example_entities => [
        {"type" => "Uri", "attributes" => { "name" => "http://www.intrigue.io" }}
      ],
      :allowed_options => [
        {:name => "threads", :type => "Integer", :regex => "integer", :default => 5 },
        {:name => "depth_limit", :type => "Integer", :regex => "integer", :default => 5 },
        {:name => "obey_robots", :type => "Boolean", :regex => "boolean", :default => false },
        {:name => "create_urls", :type => "Boolean", :regex => "boolean", :default => false },
        {:name => "show_source_uri", :type => "Boolean", :regex => "boolean", :default => true },
        {:name => "user_agent",  :type => "String",  :regex => "alpha_numeric", :default => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.111 Safari/537.36"}
      ],
      :created_types =>  ["DnsRecord", "EmailAddress", "File", "Info", "Person", "PhoneNumber" "SoftwarePackage"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    uri = _get_entity_attribute "name"

    # Scanner options
    @opt_threads = _get_option "threads"
    @opt_obey_robots = _get_option "obey_robots"
    @opt_user_agent = _get_option "user_agent"
    @opt_depth = _get_option "depth_limit"

    # Entity creation options
    @opt_show_source_uri = _get_option "show_source_uri"
    @opt_create_urls = _get_option "create_urls"

    crawl_and_parse(uri)

  end # end .run


  def crawl_and_parse(uri)
    @task_log.log "Crawling: #{uri}"

    options = {
    :threads => @opt_threads.to_i,
     :obey_robots => @opt_obey_robots,
     :user_agent => @opt_user_agent,
     :depth_limit => @opt_depth.to_i,
     :redirect_limit => 10,
     :verbose => false }

    #begin
      x = Anemone.crawl(uri, options) do |anemone|

      @task_log.log "Spider options: #{options}"

        # Spider!
        anemone.on_every_page do |page|
          begin

            # XXX - Need to set up a recursive follow-redirect function
            if page.code == 301
              @task_log.log "301 Redirect on #{page.url}"
            end

            # Extract the url
            page_uri = ("#{page.url}").encode('UTF-8', {:invalid => :replace, :undef => :replace, :replace => '?'})

            # Create an entity for this uri
            _create_entity("Uri", { "name" => page_uri, "uri" => page_uri }) if @opt_create_urls

            # If we don't have a body, we can't do anything here.
            next unless page.body

            # Extract the body
            page_body = page.body.encode('UTF-8', {:invalid => :replace, :undef => :replace, :replace => '?'})

            parse_metadata = true
            if parse_metadata

              # Get the filetype for this page
              filetype = "#{page_uri.split(".").last.gsub("/","")}".upcase

              # A list of all filetypes we're capable of doing something with
              interesting_types = [
                "DOC","DOCX","EPUB","ICA","INDD",
                "MP3","MP4","ODG","ODP","ODS","ODT",
                "PDF","PPS","PPSX","PPT","PPTX","PUB",
                "RDP","SVG","SVGZ","SXC","SXI","SXW","TIF",
                "TXT","WPD","XLS","XLSX"]

              if interesting_types.include? filetype
                download_and_extract_metadata page_uri
              else
                parse_entities_from_content(page_uri, page_body, @opt_show_source_uri)
              end

            else
              @task_log.log "Parsing as a regular file"
              parse_entities_from_content(page_uri, page_body, @opt_show_source_uri)
            end
          rescue RuntimeError => e
            @task_log.error "Caught RuntimeError: #{e}"
          end
        end #end .on_every_page
      end # end .crawl

    #rescue Exception => e
    #  @task_log.error "Encountered error: #{e.class} #{e}"
    #end #end begin
  end # crawl_and_parse

end
end
