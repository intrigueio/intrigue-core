module Intrigue
module Task
class SearchPsbdmp < BaseTask


  def self.metadata
    {
      :name => "search_psbdmp",
      :pretty_name => "Search Psbdmp",
      :authors => ["Anas Ben Salah"],
      :description => "This task hits Psbdmp api for searching dump(s) using a domain, an emailaddress and unique keyword ",
      :references => ["https://psbdmp.ws/api"],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["Domain","EmailAddress","UniqueKeyword"],
      :example_entities => [{"type" => "Domain", "details" => {"name" => "intrigue.io"}}],
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

      #headers
      headers = { "Accept" =>  "application/json"}

      #accepted entity type 
      valid_entities = ["Domain", "EmailAddress", "UniqueKeyword"] 

      if valid_entities.include? (entity_type)
        search_pastebin entity_name,headers
      else
        _log_error "Unsupported entity type"
      end
  end #end run



  def search_pastebin(entity_name,headers)
    # Get responce
    response = http_get_body("https://psbdmp.ws/api/v3/search/#{entity_name}",nil,headers) 
    result = JSON.parse(response)
    
    if result["data"]
      result["data"].each do |e|
        
        response_body = http_get_body("https://pastebin.com/#{e["id"]}")
        
        # Create an issue if we have visible data 
        if !response_body.include? "Forbidden (#403)" and !response_body.include? "Not Found (#404)"           
          _create_linked_issue("suspicious_pastebin", {
            status: "confirmed",
            description: "related pastebin found in this Url: https://pastebin.com/#{e["id"]}",
            details: e,
            source: "https://pastebin.com/#{e["id"]}"
          })
        end 
      end
    end   
  end #end search_pastebin 


end
end
end
