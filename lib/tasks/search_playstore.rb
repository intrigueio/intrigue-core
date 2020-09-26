module Intrigue
    module Task
    class SearchPlaystore < BaseTask
      def self.metadata
        {
          :name => "search_playstore",
          :pretty_name => "Search Google Playstore",
          :authors => ["shpendk"],
          :description => "Searches through the Google Playstore to find relevant mobile applications.",
          :references => [],
          :type => "discovery",
          :passive => true,
          :allowed_types => ["Organization", "String"],
          :example_entities => [
            {"type" => "String", "details" => {"name" => "intrigue"}}
          ],
          :allowed_options => [
          ],
          :created_types => ["AndroidApp"]
        }
      end
      
      def _get_json_response(uri, headers)
        begin
          response = http_request :get, uri, nil, headers
          parsed_response = JSON.parse(response.body_utf8)
        rescue JSON::ParserError => e
          _log "Error retrieving results: #{e}"
        end
      parsed_response
      end

      ## Default method, subclasses must override this
      def run
        super
    
        entity_name = _get_entity_name
    
        # search for android app via apptweak api
        api_key = _get_task_config("apptweak_api_key")
        search_uri = "https://api.apptweak.com/android/searches.json?term=#{entity_name}"
        headers = { 'X-Apptweak-Key': "#{api_key}" }

        response = _get_json_response search_uri, headers
        _log "Got apptweak response! Parsing..."
        
        if response["content"]
            # iterate through items and if entity name is in title or developer, consider a match
            response["content"].each do |app|
                is_match = false
                
                if app["title"] =~ /#{entity_name}/i
                    #_log "Found matching app #{app}"
                    is_match = true
                elsif app["developer"] =~ /#{entity_name}/i
                    is_match = true
                end

                if is_match
                    _create_entity "AndroidApp", {
                        "title" => app["title"], 
                        "name" => app["id"], #required to pass validate_entity
                        "id" => app["id"], # passing additional attribute for correctness sake
                        "developer" => app["developer"],
                        "price" => app["price"],
                        "icon_url" => app["icon"],
                        "rating" => app["rating"]
                    }
                end
            end
        else
            _log "No apps found for search term. Exiting."
            return
        end
      end
    
    end
    end
    end
    