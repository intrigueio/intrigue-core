module Intrigue
  module Task
  class SearchScylla < BaseTask
  
  
    def self.metadata
      {
        :name => "search_scylla",
        :pretty_name => "Search Scylla",
        :authors => ["Anas Ben Salah"],
        :description => "This task hits Scylla api for searching leaked EmailAddress",
        :references => ["https://scylla.so/api"],
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
        entity_type = _get_entity_type_string
        
        #headers
        headers = { "Accept" =>  "application/json"}
        
        if entity_type =="Domain"
          search_scylla_by_domain entity_name, headers
        elsif entity_type =="EmailAddress"
          search_scylla_by_email entity_name, headers
        elsif entity_type =="UniqueKeyword"
          search_scylla_by_uniquekeyword entity_name, headers
        else
          _log_error "Unsupported entity type"
        end # 
  
    end #end run

    # search scylla by a full email address 
    def search_scylla_by_email(entity_name, headers)
    # Get responce
      response = http_get_body("https://scylla.so/search?q=email:#{entity_name}&size=50&start=0",nil,headers) 
      results = JSON.parse(response)
      
      if results
        results.each do |result|

          _create_linked_issue("leaked_account",{
            name: "Email Account Found In a Public Breach Data",
            severity: 3,
            description: "Account found in publicly leaked data: #{result["fields"]["domain"]} ",
            source: "#{result["fields"]["email"]}/#{result["fields"]["domain"]}",
            details: result
          }) 
        end  
      end   
    end 

    # search scylla for a domain name 
    def search_scylla_by_domain(entity_name, headers)
      # Get responce
      response = http_get_body("https://scylla.so/search?q=email:*#{entity_name}&size=10000&start=0",nil,headers) 
      results = JSON.parse(response)
      
      if results
        results.each do |result|
          _create_linked_issue("leaked_account",{
            name: "Email Account Found In a Public Breach Data",
            severity: 3,
            description: "Account found in publicly leaked data: #{result["fields"]["domain"]} ",
            source: "#{result["fields"]["email"]}/#{result["fields"]["domain"]}",
            details: result
          }) 
        end  
      end   
    end 

    # search scylla for specific keyword 
    def search_scylla_by_uniquekeyword(entity_name, headers)
      # Get responce
      response = http_get_body("https://scylla.so/search?q=email:#{entity_name}*&size=10000&start=0",nil,headers) 
      results = JSON.parse(response)
      
      if results
        results.each do |result|
          _create_linked_issue("leaked_account",{
            name: "Email Account Found In a Public Breach Data",
            severity: 3,
            description: "Account found in publicly leaked data: #{result["fields"]["domain"]} ",
            source: "#{result["fields"]["email"]}/#{result["fields"]["domain"]}",
            details: result
          }) 
        end  
      end   
    end 
  
  
  end
  end
  end
  