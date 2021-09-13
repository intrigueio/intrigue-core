module Intrigue
  module Task
    class SearchPulsedive < BaseTask

      def self.metadata
        {
          :name => "threat/search_pulsedive",
          :pretty_name => "Threat Check - Search Pulsedive",
          :authors => ["Anas Ben Salah"],
          :description => "This task hits the Pulsedive API and enriches a domain",
          :references => ["https://pulsedive.com/api/"],
          :type => "discovery",
          :passive => true,
          :allowed_types => ["Domain", "IpAddress", "Uri"],
          :example_entities => [
            {"type" => "String", "details" => {"name" => "intrigue.io"}}
          ],
          :allowed_options => [],
          :created_types => []
        }
      end

      ## Default method, subclasses must override this
      def run
        super

        entity_name = _get_entity_name
        entity_type = _get_entity_type_string

        api_key = _get_task_config("pulsedive_api_key")

        url = "https://pulsedive.com/api/info.php?indicator=#{entity_name}&pretty=1&key=#{api_key}"

        begin

          response = http_get_body url
          result = JSON.parse(response)

          if result["risk"] == "none"
            _log "No information found about #{entity_name}"
            return
          end

          if result["risk"] == "critical"
            sev = 1
          elsif result["risk"] == "high"
            sev = 2
          elsif result["risk"] == "medium"
            sev = 3
          elsif result["risk"] == "low"
            sev = 4
          else
            sev = 5 # informational
          end


      if entity_type == "Domain" || entity_type == "IpAddress"
        
        if result["threats"]

          result["threats"].each do |u|
        
            detailed_description = "Location: #{result["properties"]["geo"]["country"]} Threats: \n" + " #{u["name"]} category: #{u["category"]} risk level: #{u["risk"]}"

            _create_linked_issue("suspicious_activity_detected",{
              source: "Pulsedive",
              severity: sev ,
              detailed_description: detailed_description,
              proof: u
            })

          end
        else
          _log "No threats detected!"
        end
    
      elsif entity_type == "Uri"
        
        if result["feeds"]
          result["feeds"].each do |v|
            _create_linked_issue("suspicious_activity_detected",{
              source: "Pulsedive",
              severity: sev ,
              detailed_description: detailed_description,
              proof: json
            })
          end
        end

      else
        _log_error "Unsupported entity type"
        return
      end


    rescue JSON::ParserError => e
      _log_error "unable to parse json!"
    end
  end #end run

end #end class
end
end
