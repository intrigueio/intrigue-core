require 'anemone'

class UriSpiderTask < BaseTask

  include Task::Web
  include Task::Parse

  def metadata
    { :version => "1.0",
      :name => "uri_spider",
      :pretty_name => "URI Spider",
      :authors => ["jcran"],
      :description => "This task spiders a given URI, creating entities.",
      :references => [],
      :allowed_types => ["Uri"],
      :example_entities => [
        {:type => "Uri", :attributes => {
          :name => "http://www.intrigue.io" }}
      ],
      :allowed_options => [
        {:name => "depth_limit", :type => "Integer", :regex => "Integer", :default => 2 },
        {:name => "obey_robots", :type => "Boolean", :regex => "(true|false)", :default => false },
        {:name => "create_urls", :type => "Boolean", :regex => "(true|false)", :default => false },
      ],
      :created_types =>  ["DnsRecord", "EmailAddress", "File", "Info", "Person", "PhoneNumber" "SoftwarePackage"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    uri = _get_entity_attribute "name"

    #@opt_depth_limit = 3 ### XXX - FIX THIS!
    #@user_options.find{ |opt| @opt_depth_limit = opt["depth_limit"]}

    #@opt_obey_robots = false ### XXX - FIX THIS!
    #@user_options.find{ |opt| @opt_obey_robots = opt["obey_robots"]}

    #@opt_create_urls = false ### XXX - FIX THIS!
    #@user_options.find{ |opt| @opt_create_urls = opt["create_urls"]}

    crawl_and_parse(uri, 2)

  end # end .run


  def crawl_and_parse(uri, depth)
    @task_log.log "Crawling: #{uri}"

    begin
      Anemone.crawl(uri, {
        :obey_robots => false,
        :user_agent => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.111 Safari/537.36",
        :depth_limit => depth,
        :redirect_limit => 5,
        :threads => 1,
        :verbose => false } ) do |anemone|

        #
        # Spider!
        #
        anemone.on_every_page do |page|

          # XXX - Need to set up a recursive follow-redirect function
          if page.code == 301
            @task_log.log "301 Redirect on #{page.url}"
            #Anemone.crawl(page.redirect_to)
          end

          #
          # Create an entity for this uri
          #
          #_create_entity("Uri", { :name => page_url}) if opt_create_urls

          ###
          ### XXX = UNTRUSTED INPUT. VERY LIKELY TO BREAK THINGS!
          ### http://po-ru.com/diary/fixing-invalid-utf-8-in-ruby-revisited/
          ###

          # Extract the url
          page_url = ("#{page.url}").encode('UTF-8', {:invalid => :replace, :undef => :replace, :replace => '?'})

          # If we don't have a body, we can't do anything here.
          next unless page.body

          # Extract the body
          page_body = page.body.encode('UTF-8', {:invalid => :replace, :undef => :replace, :replace => '?'})

          parse_metadata = true
          if parse_metadata

            # Get the filetype for this page
            filetype = "#{page_url.split(".").last.gsub("/","")}".upcase

            @task_log.log "Found filetype: #{filetype}"

            # A list of all filetypes we're capable of doing something with
            interesting_types = [
              "DOC","DOCX","EPUB","ICA","INDD","JPG","JPEG","MP3","MP4","ODG","ODP","ODS","ODT","PDF","PNG","PPS","PPSX","PPT","PPTX","PUB","RDP","SVG","SVGZ","SXC","SXI","SXW","TIF","TXT","WPD","XLS","XLSX"]


            if interesting_types.include? filetype

              result = download_and_extract_metadata page_url

              #@task_log.good "Got result #{result}"
              #_create_entity("Info", :name => "Metadata in #{page_url}", :content => result[:metadata])

              if result

                ###
                ### PDF
                ###
                if result[:content_type] == "application/pdf"

                  _create_entity "File", { :type => "PDF",
                    :name => page_url,
                    :created => result[:metadata]["Creation-Date"],
                    :last_modified => result[:metadata]["Last-Modified"]
                  }

                  _create_entity "Person", { :name => result[:metadata]["Author"], :source => page_url } if result[:metadata]["Author"]
                  _create_entity "SoftwarePackage", { :name => result[:metadata]["producer"], :source => page_url } if result[:metadata]["producer"]
                  _create_entity "SoftwarePackage", { :name => result[:metadata]["xmp:CreatorTool"], :source => page_url } if result[:metadata]["xmp:CreatorTool"]

                end

                _create_entity "Info", :name => "Metadata for #{page_url}",  :content => result[:metadata]

                # Look for entities in the text
                parse_entities_from_content(page_url, result[:text])

              else
                @task_log.error "No result received. See logs for details"
              end
            else
              parse_entities_from_content(page_url, page_body)
            end

          else

            @task_log.log "Parsing as a regular file"
            parse_entities_from_content(page_url, page_body)
          end

        end #end .on_every_page
      end # end .crawl

    # For now, we catch everything. Parsing is a messy messy beast
    # XXX - ugh

    rescue Exception => e
      @task_log.error "Encountered error: #{e.class} #{e}"
    end #end begin

  end # crawl_and_parse

end
