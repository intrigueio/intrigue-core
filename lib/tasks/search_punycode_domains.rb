require 'simpleidn'
module Intrigue
  module Task
  class SearchPunycodeDomain < BaseTask

    def self.metadata
      {
        :name => "search_punycode_domain",
        :pretty_name => "Search Punycode Domain",
        :authors => ["Anas Ben Salah"],
        :description => "This task ",
        :references => [],
        :type => "discovery",
        :passive => true,
        :allowed_types => ["String"],
        :example_entities => [{"type" => "Domain", "details" => {"name" => "München.de"}}],
        :allowed_options => [{:name => "country_code",:regex => "alpha_numeric", :default => "de" }],
        :created_types => ["Domain"]
      }
    end

    ## Default method, subclasses must override this
    def run
      super

      entity_name = _get_entity_name
      entity_type = _get_entity_type_string

      country = _get_option("country_code")

      language_exception entity_name, country

    end #end run


    def language_exception (entity_name,country)

      keyboardDe = ["ü","ö","ä","ß","Ä","Ö","Ü"]
      keyboardEs = ["á","é","í","ó","ú","ñ","Á","É","Í","Ó","Ú","Ñ"]
      keyboardFr = ["à","â","ç","é","è","ê","ë","î","ï","ï","ô","œ","ù","û"]
      keyboardPt = ["à","á","â","ã","ä","ç","é","ê","í","ó","ô","õ","ú","ü"]
      keyboardSc = ["æ","å","ä","ø","ö"]

      if country == "DEU"
        keyboardDe.each do |u|
          if entity_name.include? u
            _log "This a german website using special ASCII characters"
            create_punycode_entity entity_name
          end
        end
      elsif country == "ESP"
        keyboardEs.each do |u|
          if entity_name.include? u
            _log "This a spanish website using special ASCII characters"
            create_punycode_entity entity_name
          end
        end
      elsif country == "FRA"
        keyboardFr.each do |u|
          if entity_name.include? u
            _log "This a french website using special ASCII characters"
            create_punycode_entity entity_name
          end
        end
      elsif country == "PRT"
        keyboardPt.each do |u|
          if entity_name.include? u
            _log "This a french website using special ASCII characters"
            create_punycode_entity entity_name
          end
        end
      elsif country == "NOR" || country == "DNK" || country == "SWE"
        keyboardFr.each do |u|
          if entity_name.include? u
            _log "This a french website using special ASCII characters"
            create_punycode_entity entity_name
          end
        end
      elsif country == nil
        return
      else
        # Create an issue if the it's not german website
        create_punycode_issue entity_name
      end



    end

    def create_punycode_entity (entity_name)
      domain = SimpleIDN.to_ascii(entity_name)
      _log "encoding #{entity_name}..."
       _create_entity "Domain" , "name" => domain
    end

    def create_punycode_issue (entity_name)
      _create_linked_issue("suspicious_activity_detected", {
        status: "confirmed",
        additional_description: "This domain is using the Punycode technique to impersonate the original domain and it could be used for a phishing attack",
        proof: "This domain #{entity_name} was flagged as suspicious for impersonating reasons",
        references: ["https://www.wandera.com/punycode-attacks/"]
      })
    end

end
end
end
