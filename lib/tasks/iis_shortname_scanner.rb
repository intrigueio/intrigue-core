module Intrigue
  module Task
    class IIS_ShortnameScanner < BaseTask
      include Intrigue::Task::Web

      def self.metadata
        {
          :name => "iis_shortname_scanner",
          :pretty_name => "IIS Shortname Scanner",
          :authors => ["maxim"],
          :description => "Detects short names of files and directories which have an 8.3 file naming scheme equivalent in Windows hosted on a misconfigured IIS Server.",
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
          uri = _get_entity_name
          http_method, http_status_code = determine_vulnerable_indicators(uri)
          unless http_method.nil? || http_status_code.nil? # if http_method returns nil then target is not vulnerable
            _log_good "Host appears to be vulnerable using the #{http_method.upcase} method with the following status code as an indicator: #{http_status_code}."
            _create_linked_issue "iis_shortnames_misconfiguration"
            if bruteforce # only run if bruteforce is set to true which will bruteforce and attempt to return the shortnames of files & directories
              possible_items, possible_exts, dupes = determine_valid_chars(uri, http_method, http_status_code)
              items, exts = retrieve_shortnames(uri, http_method, http_status_code, possible_items, possible_exts)
              finished_files, finished_dirs = determine_files_or_dirs(uri, http_method, http_status_code, items, exts, dupes)
              add_files_and_dirs_to_issue(finished_files, finished_dirs)
            end
          else
            _log_error "Cowardly: Host does not appear to be running IIS. Please set override_fingerprint to true and re-run the scan to proceed."
          end
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
      # determine_method -> determines which HTTP request to use and response status code to use as an indicator that a shortname was found as newer versions of IIS can return different status codes other than 200/400/404
      def determine_vulnerable_indicators(uri)
        method = nil
        vulnerable_status_code = nil
        methods = [:get, :options]
        valid_request_codes = methods.map { |http_method| http_request(http_method, URI.escape("#{uri}/*~1*")).code }
        invalid_request_codes = methods.map { |http_method| http_request(http_method, URI.escape("#{uri}/1NTR1Z~9*")).code }
        if invalid_request_codes[0] == valid_request_codes[0] # if the invalid request (GET) status code matches the valid request (GET) status code -> move onto OPTIONS as it is not vulnerable
          if invalid_request_codes[1] != valid_request_codes[1] # if the invalid request (OPTIONS) status code does not match the valid request (OPTIONS) status code it is vulnerable
            method = :options
            vulnerable_status_code = valid_request_codes[1]
          end
        else 
          # vulnerable to GET
          method = :get
          vulnerable_status_code = valid_request_codes[0]
        end
        unless method.nil? || vulnerable_status_code.nil?
          return method, vulnerable_status_code
        else
          _log_error "Target does not appear to vulnerable to shortname scanning."
          return nil
        end
      end

      ## 
      # create_input_hash_queue -> accepts array characters which could be found in items, extensions, or duplicates and it returns the respective hash in format {character, uri}
      def create_input_hash_queue(uri, chars, type)
        queue = Hash.new
        chars.split("").each do |char|
          if type == "item"
            request_uri = "#{uri}/*#{char}*~1*" # item
            queue[char] = URI.escape(request_uri) #
          elsif type == "ext"
            request_uri = "#{uri}/*~1.*#{char}*" # ext
            queue[char] = URI.escape(request_uri) # store URI in ext hash
          elsif type == "dupes"
            request_uri = "#{uri}/*~#{char}*" # dupe
            queue[char] = URI.escape(request_uri)
          end
        end
        return queue
      end

      ##
      # threaded_http_request_from_hash_queue -> accepts an input_queue_hash which is then bruteforced and any found values are returned in the output_queue
      def threaded_http_request_from_hash_queue(input_q, output_q, http_method, match_status_code)
        t = Thread.new do
          begin
            while !input_q.empty?
              while item = input_q.shift # returns an array [character, uri]
                r = http_request http_method, item[1]
                if (r.code == match_status_code) # if response code is 404; character is valid and add to output queue
                  output_q << item[0]
                end
              end
            end
          end
        end
        return t # explicitly return our thread
      end

      ##
      # determine_valid_chars -> creates a hash queue which is then bruteforced to determine the valid characters which could be found in items, extensions, and duplicates (numbers)
      def determine_valid_chars(uri, http_method, match_status_code)
        valid_item_chars = []
        valid_ext_chars = []
        valid_dupe_chars = []
        # create hash queues in which the character is the key and the prepopulated URI is the value
        work_h_items = create_input_hash_queue uri, "abcdefghijklmnopqrstuvwxyz0123456789!#$%&\'()-@^_`{}", "item"
        work_h_exts = create_input_hash_queue uri, "abcdefghijklmnopqrstuvwxyz0123456789!#$%&\'()-@^_`{}", "ext"
        work_h_dupes = create_input_hash_queue uri, "123456789", "dupes"
        workers = (0...@opt_threads).map do
          items = threaded_http_request_from_hash_queue(work_h_items, valid_item_chars, http_method, match_status_code)
          ext = threaded_http_request_from_hash_queue(work_h_exts, valid_ext_chars, http_method, match_status_code)
          dupes = threaded_http_request_from_hash_queue(work_h_dupes, valid_dupe_chars, http_method, match_status_code)
          [items, ext, dupes]
        end
        workers.flatten.map(&:join); "Ok"
        return valid_item_chars, valid_ext_chars, valid_dupe_chars 
      end

      ##
      # bruteforce -> responsible for bruteforcing items and extensions using the valid characters retrieved earlier in order to return the full item names & full extension names
      # function takes in the required parameters along with a lambda and queues
      # the lambda is then called to generate the URI in the appropriate format depending on the type passed [item or extension]
      def bruteforce_shortname(uri, uri_format, http_method, match_status_code, in_queue, out_queue, char_list)
        t = Thread.new do
          begin
            while !in_queue.empty?
              while item = in_queue.shift
                r = http_request http_method, URI.escape(uri_format.call(uri, item))
                if r.code == match_status_code
                  r2 = http_request http_method, URI.escape(uri_format.call(uri, item, true))
                  if r2.code != match_status_code
                  # not quite full match yet
                    char_list.each do |c|
                      in_queue.push "#{item}#{c}"
                    end
                  elsif r2.code == match_status_code
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
      def retrieve_shortnames(uri, http_method, match_status_code, item_chars, ext_chars)
        item_queue = item_chars.clone
        ext_queue = ext_chars.clone
        final_item_queue = []
        final_ext_queue = []
        dynamic_item_uri_generator = -> (uri, item, final=false) { final ? "#{uri}/#{item}~1*": "#{uri}/#{item}*~1*"} # lambda which when called will return the URI in the correct format when looking for items 
        dynamic_ext_uri_generator = -> (uri, item, final=false) {final ? "#{uri}/*~1.#{item}" : "#{uri}/*~1.#{item}*"} # lambda which when called will return the URI in the correct format when looking for extensions
        workers = (0...@opt_threads/2).map do 
          items = bruteforce_shortname(uri, dynamic_item_uri_generator, http_method, match_status_code, item_queue, final_item_queue, item_chars)
          extensions = bruteforce_shortname(uri, dynamic_ext_uri_generator, http_method, match_status_code, ext_queue, final_ext_queue, ext_chars)
          [items, extensions]
        end
        workers.flatten.map(&:join); "Ok"
        return final_item_queue, final_ext_queue
      end

      ##
      # threaded_http_request_from_queue -> creates threaded http requests from a queue -> funcion is called by determine_files_or_dirs
      def threaded_http_request_from_queue(input_q, output_q, http_method, match_status_code)
        t = Thread.new do
          begin
            while !input_q.empty?
              while item = input_q.shift
                r = http_request http_method, item
                if (r.code == match_status_code)
                  output_q << URI.unescape(item)
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
        items.each do |item|
          extensions.each do |extension|
            dupes.each do |number|
              dirs_queue.push URI.escape("#{uri}/#{item}*~#{number}")
              files_queue.push URI.escape("#{uri}/#{item}*~#{number}.#{extension}*")
            end
          end
        end
        return files_queue.uniq, dirs_queue.uniq # we have to return uniq as there will be a lot of duplicates - need to find more efficient way of doing this
      end

      ##
      # determine_files_or_dirs -> uses the found items, extensions, and dupes to return an array of files and directories that were bruteforced using the bruteforce_shortname method
      def determine_files_or_dirs(uri, http_method, match_status_code, items, extensions, dupes)
        bruteforce_files_queue = []
        bruteforce_dirs_queue = []
        files = []
        dirs = []
        bruteforce_files_queue, bruteforce_dirs_queue = generate_possible_items_or_dirs_paths(uri, items, extensions, dupes)
        workers = (0...@opt_threads).map do
          file_bruteforce = threaded_http_request_from_queue(bruteforce_files_queue, files, http_method, match_status_code)
          dir_bruteforce = threaded_http_request_from_queue(bruteforce_dirs_queue, dirs, http_method, match_status_code)
          [file_bruteforce, dir_bruteforce]
        end
        workers.flatten.map(&:join); "Ok"
        return files, dirs
      end

      ##
      # add_files_and_dirs_to_issue -> if user chooses bruteforce files this method will be called when bruteforcing is finished and will update the linked issue with the discovered shortname items
      def add_files_and_dirs_to_issue(files, dirs)
        unless files.blank? || dirs.blank?
          shortname_items = { "files": files, "directories": dirs }
          _create_linked_issue "iis_shortnames_misconfiguration", { "Discovered Shortname Items": shortname_items }
          # _set_entity_detail("Discovered Shortname Items", shortname_items) # better to add into issue or add to entity details - ask Shpend tomorrow
        else
          _log "No files or directories were discovered."
          return
        end
      end

    end
  end
end
