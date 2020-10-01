module Intrigue
module Task
class SearchAdBlock < BaseTask


  def self.metadata
    {
      :name => "threat/search_adblockplus",
      :pretty_name => "Threat Check - Search AdblockPlus",
      :authors => ["Anas Ben Salah"],
      :description => "This task hits AdBlockPlus for identifying Uri's vs Adblock plus rules",
      :references => ["https://easylist-downloads.adblockplus.org/easylist.txt"],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["Uri"],
      :example_entities => [{"type" => "Uri", "details" => {"name" => "http://iyfznzgb.com/?pid=9PO1H9V71&dn=instacort.com"}}],
      :allowed_options => [],
      :created_types => []
    }
  end


  ## Default method, subclasses must override this
  def run
      super


        #get entity name and type
        entity_name = _get_entity_name
        entity_type = _get_entity_type_string

        #get keys for API authorization
        username =_get_task_config("adblockplus_username")
        api_key =_get_task_config("adblockplus_api_key")

        headers = {"Accept" =>  "application/json" ,
                  "Authorization" => "Basic #{Base64.encode64("#{username}:#{api_key}").strip}"
               }

        unless api_key or username
            _log_error "unable to proceed, no API key for AdblockPlus provided"
            return
        end

        #check for the entry type
        if entity_type == "Uri"
          search_adblockplus entity_name,headers

        #log error if you entre an Unsupported entity type
        else
          _log_error "Unsupported entity type"
        end

  end #end run

   #search if uri matches one of the adblockplus rules
  def search_adblockplus entity_name,headers
      begin
          response = http_get_body("http://127.0.0.1:5000/adblockplus/#{entity_name}",nil,headers)
          json = JSON.parse(response)

          #check if entries different to null
          if json["it_matches"] == false

          # Create linked issue
          _create_linked_issue("blocked_by_adblockplus", {
            detailed_description: "web site blocked by AdBlockPlus rules: #{_get_entity_name}.",
            details: json
          })
          end
      end #end if

  end #end SearchAdBlock

end
end
end
