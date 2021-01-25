module Intrigue
module Task
class SearchPsbdmp < BaseTask


  def self.metadata
    {
      :name => "search_psbdmp",
      :pretty_name => "Search Psbdmp",
      :authors => ["Anas Ben Salah"],
      :description => "This task hits Psbdmp api for searching dump(s) using a domain, an emailaddress and unique keyword",
      :references => ["https://psbdmp.ws/api"],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["Domain","EmailAddress","UniqueKeyword"],
      :example_entities => [{"type" => "Domain", "details" => {"name" => "intrigue.io"}}],
      :allowed_options => [],
      :created_types => ["CreditCard"]
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
          
          # get pastebin uri
          paste_uri = "https://pastebin.com/#{e["id"]}"
          
          response_body = http_get_body(paste_uri)
          
          # Create an issue if we have visible data 
          if !response_body.include? "Forbidden (#403)" and !response_body.include? "Not Found (#404)"  
            
            # Check for specific keyword if it is included in the paste to increase the severity level  
            if response_body.include? "password" or response_body.include? "breach" or               
               response_body.include? "account" or response_body.include? "cvv" or 
               response_body.include? "CreditCard" or response_body.include? "/\A[\d+\s\-]{9,20}\z/" or
               response_body.include? "/\b[\d+\s\-]{9,20}\b/"

              # create linked issue with a higher severity 
              _create_linked_issue "suspicious_pastebin", {source: paste_uri, severity: 3}
              
              # check for specifc credit cards patterns 
              if !response_body.include? "/\A[\d+\s\-]{9,20}\z/" or !response_body.include? "/\b[\d+\s\-]{9,20}\b/"

                #parse entites form body content 
                parse_and_create_entities_from_content(paste_uri, response_body)
              
              end 
            
            else
              # create linked issue
              _create_linked_issue "suspicious_pastebin", e.merge({source: paste_uri })

            end        
          end      
        end   
      end 

  end #end run


end
end
end
