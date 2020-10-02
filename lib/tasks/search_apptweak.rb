module Intrigue
  module Task
  class SearchApptweak < BaseTask
    def self.metadata
      {
        :name => "search_apptweak",
        :pretty_name => "Search Apptweak API for Android/iOS apps",
        :authors => ["shpendk"],
        :description => "Searches through the Apptweak API to find relevant mobile applications.",
        :references => [],
        :type => "discovery",
        :passive => true,
        :allowed_types => ["Organization", "String", "UniqueKeyword"],
        :example_entities => [
          {"type" => "UniqueKeyword", "details" => {"name" => "intrigue.io"}}
        ],
        :allowed_options => [
        ],
        :created_types => ["IosApp", "AndroidApp"]
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

    def match_and_create_entity(data, match_string, entity_type)
      if data["content"]
        # iterate through items and if entity name is in title or developer, consider a match
        data["content"].each do |app|
            is_match = false

            if app["title"] =~ /#{match_string}/i
                #_log "Found matching app #{app}"
                is_match = true
            elsif app["developer"] =~ /#{match_string}/i
                is_match = true
            end

            if is_match
                _create_entity entity_type, {
                    "title" => app["title"], 
                    "name" => app["id"], # using id as a name to prevent multiple entities of the same app
                    "id" => app["id"], # redundant field, but adding to "id" key as it may be needed in the future.
                    "developer" => app["developer"],
                    "price" => app["price"],
                    "icon_url" => app["icon"],
                    "rating" => app["rating"],
                    "slug" => app["slug"],
                    "devices" => app["devices"]
                }
            end
        end
    else
        _log "No apps found for search term. Exiting."
        return
    end
    end
    
    
    # search and look for android apps
    def find_android_apps(api_key, search_term)
      search_uri = "https://api.apptweak.com/android/searches.json?term=#{search_term}"
      headers = { 'X-Apptweak-Key': "#{api_key}" }

      response = _get_json_response search_uri, headers
      unless response
        _log_error "Failed to retrieve response from 42matters. Exiting!"
        return
      end

      _log "Got response! Parsing..."
      match_and_create_entity response, search_term, "AndroidApp"

    end

    # search and look for ios apps
    def find_ios_apps(api_key, search_term)
      search_uri = "https://api.apptweak.com/ios/searches.json?term=#{search_term}"
      headers = { 'X-Apptweak-Key': "#{api_key}" }

      response = _get_json_response search_uri, headers
      unless response
        _log_error "Failed to retrieve response from 42matters. Exiting!"
        return
      end

      _log "Got response! Parsing..."
      match_and_create_entity response, search_term, "IosApp"
      
    end
    
    ## Default method, subclasses must override this
    def run
      super
      _log "Running Apptweak mobile app search."
      
      entity_name = _get_entity_name
      api_key = _get_task_config("apptweak_api_key")

      unless api_key
        _log_error "Failed to retrieve api key. Exiting"
        return
      end
      
      # search for android app via apptweak api
      find_ios_apps(api_key, entity_name)
      find_android_apps(api_key, entity_name)
      
    end

  end
  end
  end