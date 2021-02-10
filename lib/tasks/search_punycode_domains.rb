module Intrigue
  module Task
  class SearchPunycodeDomain < BaseTask

    def self.metadata
      {
        :name => "search_punycode_domain",
        :pretty_name => "Search Punycode Domain",
        :authors => ["Anas Ben Salah"],
        :description => "This task search for potential suspicious domains using Punycode attack for malicious purposes ",
        :references => [],
        :type => "discovery",
        :passive => true,
        :allowed_types => ["Domain"],
        :example_entities => [{"type" => "Domain", "details" => {"name" => "munchen.de"}}],
        :allowed_options => [{:name => "country_code",:regex => "alpha_numeric", :default => "deu" }],
        :created_types => ["Domain"]
      }
    end

    ## Default method, subclasses must override this
    def run
      super

      entity_name = _get_entity_name
      domain = @entity[:details]['name']
    
      country = _get_option("country_code")

      return unless !domain.match dns_regex(true) 
        language_exception entity_name, domain, country

    end #end run


    def language_exception (entity_name, domain,country)
      
      unicode = false

      # lists of special characters for each country
      keyboardDe = ["ü","ö","ä","ß","Ä","Ö","Ü"]
      keyboardEs = ["á","é","í","ó","ú","ñ","Á","É","Í","Ó","Ú","Ñ"]
      keyboardFr = ["à","â","ç","é","è","ê","ë","î","ï","ï","ô","œ","ù","û"]
      keyboardPt = ["à","á","â","ã","ä","ç","é","ê","í","ó","ô","õ","ú","ü"]
      keyboardSc = ["æ","å","ä","ø","ö"]

      # Handling German special characters
      if country == "deu"
        keyboardDe.each do |u|
          if domain.include? u
            unicode = true 
          end
        end

        if unicode == true  
          _log "This a german website using special ASCII characters"
          create_punycode_entity domain, entity_name
        else
          create_punycode_issue domain 
        end 
      # Handling spanish special characters
      elsif country == "esp"
        keyboardEs.each do |u|
          if domain.include? u
            unicode = true
          end 
        end
        
        if unicode == true  
          _log "This a spanish website using special ASCII characters"
          create_punycode_entity domain, entity_name
        else
          create_punycode_issue domain    
        end
      # Handling french special characters
      elsif country == "fra"
        keyboardFr.each do |u|        
          if domain.include? u
            unicode = true
          end 
        end 
        if unicode == true 
          _log "This a french website using special ASCII characters"
          create_punycode_entity domain, entity_name
        else 
          create_punycode_issue domain
        end
      # Handling portuguese special characters
      elsif country == "prt"
        keyboardPt.each do |u|
          if domain.include? u
            unicode = true
          end
        end 
        if unicode == true 
          _log "This a french website using special ASCII characters"
          create_punycode_entity domain, entity_name
        else
          create_punycode_issue domain
        end
      # Handling scandinavian special characters
      elsif country == "nor" || country == "dnk" || country == "swe"
        keyboardFr.each do |u|
          if domain.include? u
            unicode = true
          end
        end 
        if unicode == true 
          _log "This a french website using special ASCII characters"
          create_punycode_entity domain, entity_name
        else 
          create_punycode_issue domain
        end
      # return in case of an empty country option  
      elsif country == ""
        return
      # Create an issue if the punycode domain does not match one of the specified countries   
      else
        create_punycode_issue domain
      end
    end

    def create_punycode_entity (domain, entity_name)

      _log "encoding #{domain}..."
      _create_entity "Domain", { "name" => entity_name, "punycode" => true}
    end

    def create_punycode_issue (domain)
      _create_linked_issue("suspicious_activity_detected", {
        status: "confirmed",
        additional_description: "This domain is using the punycode technique to impersonate the original domain and it could be used for a phishing attack",
        proof: "This domain #{domain} was flagged as suspicious for impersonating reasons",
        references: ["https://www.wandera.com/punycode-attacks/"]
      })
    end

end
end
end
