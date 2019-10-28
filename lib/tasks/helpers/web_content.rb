
module Intrigue
module Task
module WebContent

  def download_and_extract_metadata(uri,extract_content=true)

     begin
        # Download file and store locally before parsing. This helps prevent mime-type confusion
        # Note that we don't care who it is, we'll download indescriminently.
        filename = ""
        open("#{Dir::tmpdir}/#{rand(9999999999)}", "wb", {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}) do |file|
          open(uri) do |uri|
            file.write(uri.read)
            filename = file.path
          end
        end  

       mimetype = `file --brief --mime-type - < #{Shellwords.shellescape(filename)}`.strip

       ## Send to Apache Tika for analysis 
       @task_result.logger.log "Parsing #{filename}, mimetype: #{mimetype}"
       
       response = RestClient.put('http://127.0.0.1:9998/rmeta', File.open(filename,"rb").read, :accept => "application/json",:'content-type' => mimetype )
       metadata = JSON.parse(response).first

       # Handle audio files
       if metadata["Content-Type"] == "audio/mpeg" # Handle MP3/4
         _create_entity "Person", {"name" => metadata["meta:author"], "origin" => uri }
         _create_entity "Person", {"name" => metadata["creator"], "origin" => uri }
         _create_entity "Person", {"name" => metadata["xmpDM:artist"], "origin" => uri }

       elsif metadata["Content-Type"] == "application/pdf" # Handle PDF

         _create_entity "Person", {"name" => metadata["Author"], "origin" => uri, "modified" => metadata["Last-Modified"] } if metadata["Author"]
         _create_entity "Person", {"name" => metadata["meta:author"], "origin" => uri, "modified" => metadata["Last-Modified"] } if metadata["meta:author"]
         _create_entity "Person", {"name" => metadata["dc:creator"], "origin" => uri, "modified" => metadata["Last-Modified"] } if metadata["dc:creator"]
         _create_entity "Person", {"name" => metadata["xmp:CreatorTool"], "origin" => uri, "modified" => metadata["Last-Modified"] } if metadata["xmp:CreatorTool"]
         _create_entity "Organization", {"name" => metadata["Company"], "origin" => uri, "modified" => metadata["Last-Modified"] } if metadata["Company"]
         
       end

       # Look for entities in the text of the entity
       parse_entities_from_content(uri,metadata["X-TIKA:content"]) if extract_content

     rescue RuntimeError => e
      @task_result.logger.log_error "Runtime error: #{e}"
     rescue EOFError => e
       @task_result.logger.log_error "Unable to parse file: #{e}"
     rescue OpenURI::HTTPError => e     # don't die if we can't find the file
       @task_result.logger.log_error "Unable to download file: #{e}"
     rescue URI::InvalidURIError => e     # handle invalid uris
       @task_result.logger.log_error "Unable to download file: #{e}"
     rescue JSON::ParserError => e
       @task_result.logger.log_error "Unable to parse file: #{e}"
     end

   # return metadata
   metadata
   end


   ###
   ### Entity Parsing
   ###
   def parse_entities_from_content(source_uri, content)
     parse_email_addresses_from_content(source_uri, content)
     parse_dns_records_from_content(source_uri, content)
     parse_phone_numbers_from_content(source_uri, content)
     #parse_uris_from_content(source_uri, content)
   end

   def parse_email_addresses_from_content(source_uri, content)

     @task_result.logger.log "Parsing text from #{source_uri}" if @task_result

     # Make sure we have something to parse
     unless content
       @task_result.logger.log_error "No content to parse, returning" if @task_result
       return nil
     end

     # Scan for email addresses
     addrs = content.scan(/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,8}/)
     addrs.each do |addr|
       x = _create_entity("EmailAddress", {"name" => addr, "origin" => source_uri}) unless addr =~ /.png$|.jpg$|.gif$|.bmp$|.jpeg$/
     end

   end

   def parse_dns_records_from_content(source_uri, content)

     @task_result.logger.log "Parsing text from #{source_uri}" if @task_result

     # Make sure we have something to parse
     unless content
       @task_result.logger.log_error "No content to parse, returning" if @task_result
       return nil
     end

     # Scan for dns records
     dns_records = content.scan(/^[A-Za-z0-9]+\.[A-Za-z0-9]+\.[a-zA-Z]{2,6}$/)
     dns_records.each do |dns_record|
       x = _create_entity("DnsRecord", {"name" => dns_record, "origin" => source_uri})
     end
   end

   def parse_phone_numbers_from_content(source_uri, content)

     @task_result.logger.log "Parsing text from #{source_uri}" if @task_result

     # Make sure we have something to parse
     unless content
       @task_result.logger.log_error "No content to parse, returning" if @task_result
       return nil
     end

     # Scan for phone numbers
     phone_numbers = content.scan(/((\+\d{1,2}\s)?\(?\d{3}\)?[\s.-]\d{3}[\s.-]\d{4})/)
     phone_numbers.each do |phone_number|
       x = _create_entity("PhoneNumber", { "name" => "#{phone_number[0]}", "origin" => source_uri})
     end
   end

   def parse_uris_from_content(source_uri, content)

     @task_result.logger.log "Parsing text from #{source_uri}" if @task_result

     # Make sure we have something to parse
     unless content
       @task_result.logger.log_error "No content to parse, returning" if @task_result
       return nil
     end

     # Scan for uris
     urls = content.scan(/https?:\/\/[\S]+/)
     urls.each do |url|
       _create_entity("Uri", {"name" => url, "uri" => url, "origin" => source_uri })
     end
   end

   def parse_web_account_from_uri(url)
     # Handle Twitter search results
     if url =~ /https?:\/\/twitter.com\/.*$/
       account_name = url.split("/")[3]
       _create_entity("WebAccount", {
         "domain" => "twitter.com",
         "name" => account_name,
         "uri" => "#{url}",
         "type" => "full"
       })

     # Handle Facebook public profile  results
     elsif url =~ /https?:\/\/www.facebook.com\/(public|pages)\/.*$/
       account_name = url.split("/")[4]
       _create_entity("WebAccount", {
         "domain" => "facebook.com",
         "name" => account_name,
         "uri" => "#{url}",
         "type" => "public"
       })

     # Handle Facebook search results
     elsif url =~ /https?:\/\/www.facebook.com\/.*$/
       account_name = url.split("/")[3]
       _create_entity("WebAccount", {
         "domain" => "facebook.com",
         "name" => account_name,
         "uri" => "#{url}",
         "type" => "full"
       })

     # Handle LinkedIn public profiles
     elsif url =~ /^https?:\/\/www.linkedin.com\/in\/pub\/.*$/
         account_name = url.split("/")[5]
         _create_entity("WebAccount", {
           "domain" => "linkedin.com",
           "name" => account_name,
           "uri" => "#{url}",
           "type" => "public"
         })

     # Handle LinkedIn public directory search results
     elsif url =~ /^https?:\/\/www.linkedin.com\/pub\/dir\/.*$/
       account_name = "#{url.split("/")[5]} #{url.split("/")[6]}"
       _create_entity("WebAccount", {
         "domain" => "linkedin.com",
         "name" => account_name,
         "uri" => "#{url}",
         "type" => "public"
       })

     # Handle LinkedIn world-wide directory results
     elsif url =~ /^http:\/\/[\w]*.linkedin.com\/pub\/.*$/

     # Parses these URIs:
     #  - http://za.linkedin.com/pub/some-one/36/57b/514
     #  - http://uk.linkedin.com/pub/some-one/78/8b/151

       account_name = url.split("/")[4]
       _create_entity("WebAccount", {
         "domain" => "linkedin.com",
         "name" => account_name,
         "uri" => "#{url}",
         "type" => "public" })

     # Handle LinkedIn profile search results
     elsif url =~ /^https?:\/\/www.linkedin.com\/in\/.*$/
       account_name = url.split("/")[4]
       _create_entity("WebAccount", {
         "domain" => "linkedin.com",
         "name" => account_name,
         "uri" => "#{url}",
         "type" => "public" })

     # Handle Google Plus search results
     elsif url =~ /https?:\/\/plus.google.com\/.*$/
       account_name = url.split("/")[3]
       _create_entity("WebAccount", {
         "domain" => "google.com",
         "name" => account_name,
         "uri" => "#{url}",
         "type" => "full" })

     # Handle Hackerone search results
     elsif url =~ /https?:\/\/hackerone.com\/.*$/
       account_name = url.split("/")[3]
       _create_entity("WebAccount", {
         "domain" => "hackerone.com",
         "name" => account_name,
         "uri" => url,
         "type" => "full" }) unless account_name == "reports"
     end
   end


end
end
end
