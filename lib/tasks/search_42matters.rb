module Intrigue
    module Task
    class SearchFourtyTwoMatters < BaseTask
      def self.metadata
        {
          :name => "search_42matters",
          :pretty_name => "Search 42matters API for Android/iOS apps",
          :authors => ["shpendk"],
          :description => "Searches through the 42matters API to find relevant mobile applications.",
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
      
      # search and look for android apps
      def find_android_apps(api_key, search_term)
        search_uri = "https://data.42matters.com/api/v2.0/android/apps/query.json?access_token=#{api_key}"
        data = {
          "query" => {
            "query_params" => {
              "from": 0,
              "sort": "score",
              "include_full_text_desc": true,
              "include_developer": true,
              "full_text_term": "#{search_term}"
            }
          }
        }
        
        response = http_request :post , search_uri, nil, {}, data.to_json, true, 60
       
        unless response
          _log_error "Failed to retrieve response from 42matters. Exiting!"
          return
        end

        _log "Got response! Parsing..."
        response_json = JSON.parse(response.body)
        
        if response_json["results"]
          # iterate through items and if entity name is in title or developer, consider a match
          response_json["results"].each do |app|
              is_match = false

              if app["title"] =~ /#{search_term}/i
                  #_log "Found matching app #{app}"
                  is_match = true
              elsif app["developer"] =~ /#{search_term}/i
                  is_match = true
              elsif app["description"] =~ /#{search_term}/i
                is_match = true
              end
  
              if is_match
                  _create_entity "AndroidApp", {
                    "description" => app["description"], 
                    "name" => app["package_name"], # setting name to app package_name so we don't create multiple entities of the same app
                    "package_name" => app["package_name"], # redundant field, but adding to as it may be needed in the future.
                    "price" => app["price"], 
                    "min_sdk" => app["min_sdk"],
                    "version" => app["version"],
                    "short_description" => app["short_desc"],
                    "downloads" => app["downloads"],
                    "email" => app["email"],
                    "website" => app["website"],
                    "category" => app["category"],
                    "developer" => app["developer"],
                    "icon" => app["icon"]
                  }
              end
          end
      else
          _log "No apps found for search term. Exiting."
          return
      end
      end
  
      # search and look for ios apps
      def find_ios_apps(api_key, search_term)
        search_uri = "https://data.42matters.com/api/v2.0/ios/apps/query.json?access_token=#{api_key}"
        data = {
          "query" => {
            "query_params" => {
              "from": 0,
              "sort": "score",
              "include_full_text_desc": true,
              "include_developer": true,
              "full_text_term": "#{search_term}"
            }
          }
        }
        
        response = http_request :post , search_uri, nil, {}, data.to_json, true, 60

        unless response
          _log_error "Failed to retrieve response from 42matters. Exiting!"
          return
        end

        _log "Got response! Parsing..."
        response_json = JSON.parse(response.body)

        if response_json["results"]
          # iterate through items and if entity name is in title or developer, consider a match
          response_json["results"].each do |app|
              is_match = false
  
              if app["description"] =~ /#{search_term}/i
                  #_log "Found matching app #{app}"
                  is_match = true
              elsif app["sellerName"] =~ /#{search_term}/i
                  is_match = true
              end
  
              if is_match
                  _create_entity "IosApp", {
                      "title" => app["description"], 
                      "name" => app["trackId"], # setting name to trackId which is the unique app id, so as to prevent multiple entities of the same
                      "id" => app["trackId"], # redundant field, but adding to "id" key as it may be needed in the future.
                      "bundle_id" => app["bundleId"], 
                      "developer" => app["sellerName"],
                      "price" => app["price"],
                      "icon_url" => app["artworkUrl60"],
                      "rating" => app["averageUserRating"],
                      "app_url" => app["trackViewUrl"],
                      "email" => app["email"],
                      "minimum_os_version" => app["minimumOsVersion"],
                      "permissions" => app["permissions"],
                      "version" => app["version"],
                      "size_in_bytes" => app["fileSizeBytes"],
                      "developer_url" => app["sellerUrl"],
                      "supported_devices" => app["supportedDevices"],
                      "support_url" => app["supportUrl"],
                      "current_release_date" => app["currentVersionReleaseDate"],
                      "first_release_date" => app["releaseDate"]
                  }
              end
          end
      else
          _log "No apps found for search term. Exiting."
          return
      end
      end
      
      ## Default method, subclasses must override this
      def run
        super
        _log "Running 42matters mobile app search."
        
        entity_name = _get_entity_name
        api_key = _get_task_config("42matters_api_key")
  
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