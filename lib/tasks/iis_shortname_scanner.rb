module Intrigue
  module Task
    class IIS_ShortnameScanner < BaseTask
      include Intrigue::Task::Web

      def self.metadata
        {
          :name => "iis_shortnames_misconfiguration",
          :pretty_name => "IIS Shortname Scanner",
          :authors => ["maxim"],
          :description => "Detects short names of files and directories which have an 8.3 file naming scheme equivalent in Windows hosted on a misconfigured IIS Server. By default this only returns whether the host is vulnerable. By setting the bruteforce parameter to true, it will attempt to bruteforce these shortnames.",
          :references => [
            "https://soroush.secproject.com/downloadable/microsoft_iis_tilde_character_vulnerability_feature.pdf",
            "https://github.com/irsdl/IIS-ShortName-Scanner",
            "https://support.detectify.com/support/solutions/articles/48001048944-microsoft-iis-tilde-vulnerability",
            "https://www.acunetix.com/vulnerabilities/web/microsoft-iis-tilde-directory-enumeration/",
          ],
          :type => "discovery",
          :passive => false,
          :allowed_types => ["Uri"],
          :example_entities => [
            { "type" => "Uri", "details" => { "name" => "http://intrigue.io" } },
          ],
          :allowed_options => [
            { :name => "ignore_override_fingerprint", :regex => "boolean", :default => false },
            { :name => "bruteforce", :regex => "boolean", :default => false},
            { :name => "threads", :regex => "integer", :default => 20 },
          ],
          :created_types => ["Uri"],
        }
      end

      def run
        super

        override = _get_option("ignore_override_fingerprint")
        bruteforce = _get_option("bruteforce")
        @opt_threads = _get_option("threads").abs() # in case a negative thread is passed
        
        # check if we have fingeprint for this URI
        if _get_entity_detail("fingerprint").nil? 
          require_enrichment # force enrichment to return a fingerprint
        end

        # only run if target is running IIS or if override_fingerprint is set to true
        if (is_iis? || override)
          _log "Host appears to be running IIS. Proceeding with checking if it is vulnerable to Shortname Scanning."
          uri = _get_entity_name
          http_method, vuln_indicator = determine_vulnerable_indicators(uri)

          unless http_method.nil? || vuln_indicator.nil? # if http_method returns nil then target is not vulnerable
            _log_good "Host appears to be vulnerable using the #{http_method.upcase} method with the #{vuln_indicator.keys[0]} as the indicator."

            unless bruteforce
             _create_linked_issue "iis_shortnames_misconfiguration"
            else # only run if bruteforce is set to true which will bruteforce and attempt to return the shortnames of files & directories
              possible_items, possible_exts, dupes = determine_valid_chars(uri, http_method, vuln_indicator)
              items, exts = retrieve_shortnames(uri, http_method, vuln_indicator, possible_items, possible_exts)
              finished_files, finished_dirs = determine_files_or_dirs(uri, http_method, vuln_indicator, items, exts, dupes)
              add_files_and_dirs_to_issue(finished_files, finished_dirs)
            end
          end
        else
          _log_error "Cowardly: Host does not appear to be running IIS. Please set override_fingerprint to true and re-run the scan to proceed."
        end
      end

      ##
      # is_iis? -> determines if the target host is running IIS in order to cut down on false positives
      def is_iis?
        found_iss = false
        fp = _get_entity_detail("fingerprint")
        fp.each do |f|
          if f["vendor"] == "Microsoft" && f["product"] == "Internet Information Services"
            found_iss = true
            break
          end
        end
        return found_iss
      end

      ##
      # verify_response_dupes -> takes in two arrays [valid, invalid]. checks to see if the all the values in the valid arrays are the same and then if any of the values in in the valid arrays exist in the invalid one
      def verify_response_dupes(valid_items, invalid_items)
        if valid_items.uniq.count <= 1 # check if all items  in array are the same
          unless valid_items.any? {|code| invalid_items.include? code }  # are any of the valid items contained in the invalid item array?
           # they are not... meaning this is an indication it is vulnerable
            return true
          end
        end 
        return false 
      end

      ##
      # verify_via_status_codes -> responsible for verifying if host is vulnerable by using status codes as an indicator (majority of hosts are)
      def verify_via_status_codes(uri, request_uri_builder)
        method = nil
        vulnerable_indicator = nil

         # OPTIONS method has precedence 
        valid_option_codes = ["*~1*", "*~1**"].map {|p| request_uri_builder.call(uri, p, :options).code}
        invalid_option_codes = ["1NTR1Z~9*", "1111*****33222"].map {|p| request_uri_builder.call(uri, p, :options).code} # two different OPTIONS requests to confirm validity

        if valid_option_codes.include? "0" # if 0 is found in the status code we want to skip it as some WAF's simply drop the request causing typhoeus to timeout thus returning a status code of 0
          _log_error "Unable to retrieve responses; most likely WAF is dropping the request. Killing scan."
          return
        end

        unless verify_response_dupes(valid_option_codes, invalid_option_codes) == false 
          method = :options 
          vulnerable_indicator = {"status_code" => valid_option_codes.uniq.first}
        else # OPTIONS did not work - send GET requests as last resort
          valid_get_codes = ["*~1*", "*~1**"].map {|p| request_uri_builder.call(uri, p, :get).code}
          invalid_get_codes = ["1NTR1Z~9*", "Z1RTN1~9*"].map {|p| request_uri_builder.call(uri, p, :get).code}

          unless verify_response_dupes(valid_get_codes, invalid_get_codes) == false
            method = :get
            vulnerable_indicator = {"status_code" => valid_get_codes.uniq.first}
          end
        end
        return method, vulnerable_indicator
      end

      ##
      # verify_via_response_length -> responsible for verifying if host is vulnerable by using response lengths as an indicator
      def verify_via_response_length(uri, request_uri_builder)
        method = nil
        vulnerable_indicator = nil
     
        # it is IMPERATIVE that the amount of characters match both in valid & invalid requests in case the response body reflects the query
        valid_option_length = ["******~1*", "*~1******"].map {|p| request_uri_builder.call(uri, p, :options).body.size} # we send two valid requests
        invalid_option_length = ["1NTR1Z~9*", "Z1RNT1~9*"].map {|p| request_uri_builder.call(uri, p, :options).body.size} # send two invalid requests

        unless verify_response_dupes(valid_option_length, invalid_option_length) == false # 
          method = :options
          vulnerable_indicator = {"response_length" => valid_option_length.uniq.first}
        else
          # OPTIONS did not work -> try with GET requests
          valid_get_length = ["******~1*", "*~1******"].map {|p| request_uri_builder.call(uri, p, :get).body.size}
          invalid_get_length = ["1NTR1Z~9*", "Z1RNT1~9*"].map {|p| request_uri_builder.call(uri, p, :get).body.size}

          unless verify_response_dupes(valid_get_length, invalid_get_length) == false
            method = :get
            vulnerable_indicator = {"response_length" => valid_get_length.uniq.first}
          end
        end
        return method, vulnerable_indicator
      end
        

      ##
      # determine_vulnerable_indicators -> determines what to use (status or response length) as an indicator that the host is vulnerable
      # if host is deemed vulnerable; a hash will be returned in the following format {'vulnerable_type', 'vulnerable_indicator'}
      # an example of the above could be status with response code 404 which will look: {'status_code', '404'}
      def determine_vulnerable_indicators(uri)      
        # lambda to generate the appropriate request_uri, the parameters at the end are the default ones that go along with http_request however we disable redirects (hence the false)
        uri_builder = -> (uri, path, http_method) { http_request(http_method, "#{uri}/#{URI.encode_www_form_component(path)}", nil, {}, nil, false, 10)}
        # first attempt to verify this is vulnerable via response_status_codes (as it appears majority are)
        method, vulnerable_indicator = verify_via_status_codes(uri, uri_builder)
        
        if method.nil? || vulnerable_indicator.nil? 
          # if the the response_status_code verification failed -> move onto response length as the last resort
          method, vulnerable_indicator = verify_via_response_length(uri, uri_builder)
        end

        unless method.nil? || vulnerable_indicator.nil?
          return method, vulnerable_indicator
        else
          _log_error "Target does not appear to be vulnerable to shortname scanning."
          return nil
        end
      end

      ## 
      # create_input_hash_queue -> accepts array characters which could be found in items, extensions, or duplicates and it returns the respective hash in format {character, uri}
      def create_input_hash_queue(uri, chars, type)
        queue = Hash.new
        chars.split("").each do |char|
          if type == "item"
            path = "*#{char}*~1*"
            request_uri = "#{uri}/#{URI.encode_www_form_component(path)}"
            queue[char] = request_uri
          elsif type == "ext"
            path = "*~1.*#{char}*"
            request_uri = "#{uri}/#{URI.encode_www_form_component(path)}" # ext
            queue[char] = request_uri
          elsif type == "dupes"
            request_uri = "#{uri}/#{URI.encode_www_form_component("*~#{char}*")}" # dupe
            queue[char] = request_uri
          end
        end
        return queue
      end

      ##
      # threaded_http_request_from_hash_queue -> accepts an input_queue_hash which is then bruteforced and any found values are returned in the output_queue
      def threaded_http_request_from_hash_queue(input_q, output_q, http_method, vuln_indicator)
        t = Thread.new do
          begin
            while !input_q.empty?
              while item = input_q.shift # returns an array [character, uri]
                r = http_request http_method, item[1]
                check = -> (r, type) { type == "response_length" ? r.body.size : r.code  }  # lambda to determine the type of vulnerable indicator to look out for (the type is passed earlier from the determine_vulnerable_indicators method)
                if (check.call(r, vuln_indicator.keys[0]) == vuln_indicator.values[0] ) # match the returned value of the check lambda to the value stored in the vulnerable_indicators hash which would either be the status code or response length 
                  output_q << item[0]
                end
              end
            end
          end
        end
        return t # explicitly return our thread
      end

      ##
      # check_fp_chars -> is called when we're using the status code as an indicator
      # some IIS hosts will return the SAME STATUS CODE but a DIFFERENT RESPONSE SIZE based on specific special characters such as & % ; 
      # this method will take a baseline of the response size of a valid shortname payload and then compare the characters it found to remove any unwanted false positives
      def check_fp_chars(uri, http_method, char_list, response_length, include_ext=false)
        request_uri = -> (uri, item, ext) { ext ? "#{uri}/#{URI.encode_www_form_component("*~1.*#{item}*")}" : "#{uri}/#{URI.encode_www_form_component("*#{item}*~1.*")}" } # lambda to generate the correct URI format (item/extension)
        output_queue = []
        input_queue = char_list.map {|c| [c, request_uri.call(uri, c, include_ext)] }.to_h
        workers = (0...@opt_threads).map do
          chars = threaded_http_request_from_hash_queue(input_queue, output_queue, http_method, {"response_length"=> response_length})
          [chars]
        end
        workers.flatten.map(&:join); "Ok"
        return output_queue
      end

      ##
      # determine_valid_chars -> creates a hash queue which is then bruteforced to determine the valid characters which could be found in items, extensions, and duplicates (numbers)
      def determine_valid_chars(uri, http_method, vuln_indicator)
        valid_item_chars = []
        valid_ext_chars = []
        valid_dupe_chars = []

        # create hash queues in which the character is the key and the prepopulated URI is the value
        work_h_items = create_input_hash_queue uri, "abcdefghijklmnopqrstuvwxyz0123456789!#$%&\'()-@^_`{}", "item"
        work_h_exts = create_input_hash_queue uri, "abcdefghijklmnopqrstuvwxyz0123456789!#$%&\'()-@^_`{}", "ext"
        work_h_dupes = create_input_hash_queue uri, "123456789", "dupes"

        workers = (0...@opt_threads).map do
          items = threaded_http_request_from_hash_queue(work_h_items, valid_item_chars, http_method, vuln_indicator)
          ext = threaded_http_request_from_hash_queue(work_h_exts, valid_ext_chars, http_method, vuln_indicator)
          dupes = threaded_http_request_from_hash_queue(work_h_dupes, valid_dupe_chars, http_method, vuln_indicator)
          [items, ext, dupes]
        end
        workers.flatten.map(&:join); "Ok"

        unless vuln_indicator.values[0] == "response_length"
          # this only applies when the status code is being used as the indicator whether or not a character is valid. the reason behind this is that certain IIS or app configs will return the same status code but different response length depending on the character (this mostly applies to special characters such as % &)
          length = http_request(http_method, "#{uri}/***~1.*").body.size
          checked_items = check_fp_chars(uri, http_method, valid_item_chars, length)
          checked_extensions = check_fp_chars(uri, http_method, valid_ext_chars, length, true)
        end
        
        # only return items that are found in both arrays meaning remove false positives
        valid_item_chars = valid_item_chars & checked_items 
        valid_ext_chars = valid_ext_chars & checked_extensions 

        return valid_item_chars, valid_ext_chars, valid_dupe_chars 
      end

      ##
      # bruteforce -> responsible for bruteforcing items and extensions using the valid characters retrieved earlier in order to return the full item names & full extension names
      # function takes in the required parameters along with a lambda and queues
      # the lambda is then called to generate the URI in the appropriate format depending on the type passed [item or extension]
      def bruteforce_shortname(uri, uri_format, http_method, vuln_indicator, in_queue, out_queue, char_list)
        t = Thread.new do
          begin
            # lambda to determine the type of vulnerable indicator to look out for (the type is passed earlier from the determine_vulnerable_indicators method)
            check = -> (r, type) { type == "response_length" ? r.body.size : r.code  } 
            while !in_queue.empty?
              while item = in_queue.shift
                r = http_request http_method, uri_format.call(uri, item)
                if (check.call(r, vuln_indicator.keys[0]) == vuln_indicator.values[0] ) # match the returned value of the check lambda to the value stored in the vulnerable_indicators hash which would either be the status code or response length
                  r2 = http_request http_method, uri_format.call(uri, item, true) # if the above returns true; send an additional request to confirm this is the final item
                  if (check.call(r2, vuln_indicator.keys[0]) != vuln_indicator.values[0] )
                  # not quite full match yet
                    char_list.each do |c| # create all possible permutations of the item using the character list and throw it back into the input queue
                      in_queue.push "#{item}#{c}"
                    end
                  elsif (check.call(r2, vuln_indicator.keys[0]) == vuln_indicator.values[0]) # this is the final item; move onto next line and add to the output_queue
                    # full match
                    out_queue.push "#{item}"
                  end
                end
              end
            end
          end
        end
        return t
      end
      
      ##
      # retrieve_shortnames -> calls bruteforce method to fill up the final_item_queue & final_ext_queue
      def retrieve_shortnames(uri, http_method, vuln_indicator, item_chars, ext_chars)
        item_queue = item_chars.clone
        ext_queue = ext_chars.clone
        final_item_queue = []
        final_ext_queue = []

        # lambdas to generate the appropriate URI (either item or extension)
        dynamic_item_uri_generator = -> (uri, item, final=false) { final ? "#{uri}/#{URI.encode_www_form_component("#{item}~1*")}" : "#{uri}/#{URI.encode_www_form_component("#{item}*~1*")}" }               # lambda which when called will return the URI in the correct format when looking for items 
        dynamic_ext_uri_generator = -> (uri, item, final=false) {final ? "#{uri}/#{URI.encode_www_form_component("*~1.#{item}")}" : "#{uri}/#{URI.encode_www_form_component("*~1.#{item}*")}" } # lambda which when called will return the URI in the correct format when looking for extensions
        
        workers = (0...@opt_threads/2).map do 
          items = bruteforce_shortname(uri, dynamic_item_uri_generator, http_method, vuln_indicator, item_queue, final_item_queue, item_chars)
          extensions = bruteforce_shortname(uri, dynamic_ext_uri_generator, http_method, vuln_indicator, ext_queue, final_ext_queue, ext_chars)
          [items, extensions]
        end

        workers.flatten.map(&:join); "Ok"
        return final_item_queue, final_ext_queue
      end

      ##
      # threaded_http_request_from_queue -> creates threaded http requests from a queue -> funcion is called by determine_files_or_dirs
      def threaded_http_request_from_queue(input_q, output_q, http_method, vuln_indicator)
        t = Thread.new do
          begin
            check = -> (r, type) { type == "response_length" ? r.body.size : r.code  }
            while !input_q.empty?
              while item = input_q.shift
                r = http_request http_method, item
                if (check.call(r, vuln_indicator.keys[0]) == vuln_indicator.values[0] )
                  output_q << CGI.unescape(item)
                end
              end
            end
          end
        end
        return t # explicitly return our thread
      end

      ##
      # create_items_bruteforce_queue -> passed in an array of items, extensions, and dupes which are then used to create a queue of bruteforcable requests
      def generate_possible_items_or_dirs_paths(uri, items, extensions, dupes)
        files_queue = []
        dirs_queue = []

        extensions = [""] if extensions.empty? # we need at least an empty value in the array or it will kill the upcoming iteration

        items.each do |item|
          extensions.each do |extension|
            dupes.each do |number|
              dirs_queue.push "#{uri}/#{URI.encode_www_form_component("#{item}*~#{number}")}"
              unless extension.empty? # due to how wildcards in IIS work, check if the extension is empty or else it will be returned as a filename as well
                files_queue.push "#{uri}/#{URI.encode_www_form_component("#{item}*~#{number}.#{extension}*")}" 
              end
            end
          end
        end
        return files_queue.uniq, dirs_queue.uniq # we have to return uniq as there will be a lot of duplicates - need to find more efficient way of doing this
      end

      ##
      # determine_files_or_dirs -> uses the found items, extensions, and dupes to return an array of files and directories that were bruteforced using the bruteforce_shortname method
      def determine_files_or_dirs(uri, http_method, vuln_indicator, items, extensions, dupes)
        bruteforce_files_queue = []
        bruteforce_dirs_queue = []
        files = []
        dirs = []

        bruteforce_files_queue, bruteforce_dirs_queue = generate_possible_items_or_dirs_paths(uri, items, extensions, dupes)
        workers = (0...@opt_threads).map do
          file_bruteforce = threaded_http_request_from_queue(bruteforce_files_queue, files, http_method, vuln_indicator)
          dir_bruteforce = threaded_http_request_from_queue(bruteforce_dirs_queue, dirs, http_method, vuln_indicator)
          [file_bruteforce, dir_bruteforce]
        end

        workers.flatten.map(&:join); "Ok"
        return files, dirs
      end

      ##
      # add_files_and_dirs_to_issue -> if user chooses bruteforce files this method will be called when bruteforcing is finished and will update the linked issue with the discovered shortname items
      def add_files_and_dirs_to_issue(files, dirs)
        unless files.blank? && dirs.blank?
          shortname_items = { "files": files, "directories": dirs }
          _log_good "Discovered #{files.size} files and #{dirs.size} directories."
          _create_linked_issue "iis_shortnames_misconfiguration", { "Discovered Shortname Items": shortname_items }
        else
          _log "No files or directories were discovered."
          _create_linked_issue "iis_shortnames_misconfiguration", { "Discovered Shortname Items": "None" }
          return
        end
      end

    end
  end
end
