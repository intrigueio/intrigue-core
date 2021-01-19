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

      #get entity name 
      entity_name = _get_entity_name
   
      #headers
      headers = { "Accept" =>  "application/json"}
      
      # Get responce
      response = http_get_body("https://psbdmp.ws/api/v3/search/#{entity_name}",nil,headers) 
      result = JSON.parse(response)
      
      if result["data"]
        result["data"].each do |e|
          
          response_body = http_get_body("https://pastebin.com/#{e["id"]}")
          
          # Create an issue if we have visible data 
          if !response_body.include? "Forbidden (#403)" and !response_body.include? "Not Found (#404)"  
            
            # Check for specific keyword if it is included in the paste to increase the severity level  
            if response_body.include? "password" or response_body.include? "cvv" or response_body.include? "card" or 
               response_body.include? "breach" or response_body.include? "account" 

               _create_linked_issue "suspicious_pastebin", e.merge({source: "https://pastebin.com/#{e["id"]}" }, severity: 3)
            else
              _create_linked_issue "suspicious_pastebin", e.merge({source: "https://pastebin.com/#{e["id"]}" })
            
            end        
          end      
        end   
      end 

  end #end run


end
end
end
