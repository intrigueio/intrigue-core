module Intrigue
  module Task
    class SearchPulsedive < BaseTask

      def self.metadata
        {
          :name => "search_pulsedive",
          :pretty_name => "Search Pulsedive",
          :authors => ["Anas Ben Salah"],
          :description => "This task hits the Pulsedive API and enriches a domain",
          :references => ["https://pulsedive.com/api/"],
          :type => "discovery",
          :passive => true,
          :allowed_types => ["Domain","IpAddress","Uri"],
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
        unless api_key
          _log_error "unable to proceed, no API key for Pulsedive provided"
          return
        end

        url = "https://pulsedive.com/api/info.php?indicator=#{entity_name}&pretty=1&key=#{api_key}"

        begin

          response = http_get_body url
          json = JSON.parse(response)

          if json["risk"] == "none"
            return
          end

          puts entity_type

          if json["risk"] == "critical"
            sev = 5
          elsif json["risk"] == "high"
            sev = 4
          elsif json["risk"] == "medium"
            sev = 3
          elsif json["risk"] == "low"
            sev = 2
          else
            return
          end


            if entity_type == "Domain"
              json["threats"].each do |u|
              # create an issue to track this
              _create_issue({
                name: "#{entity_name}  [Pulsedive]",
                type: "Malicious Domain",
                severity: sev ,
                status: "confirmed",
                description: "Location: #{json["properties"]["geo"]["country"]} Threats: \n" + " #{u["name"]} category: #{u["category"]} risk level: #{u["risk"]}",
                details: json
                })
              end
              elsif entity_type == "IpAddress"
                json["threats"].each do |u|
                # create an issue to track this
                _create_issue({
                  name: "#{entity_name}  [Pulsedive]",
                  type: "Malicious IP",
                  severity: sev ,
                  status: "confirmed",
                  description: "Location: #{json["properties"]["geo"]["country"]} Threats: \n" + " #{u["name"]} category: #{u["category"]} risk level: #{u["risk"]}",
                  details: json
                  })
                end
              elsif entity_type == "Uri"
                  puts entity_type
                  json["feeds"].each do |v|
                 # create an issue to track this
                  _create_issue({
                    name: "#{entity_name}  [Pulsedive]",
                    type: "Malicious URL",
                    severity: sev ,
                    status: "confirmed",
                    description: "Location: #{json["properties"]["geo"]["country"]} Threats: \n" + " #{v["name"]} category: #{v["category"]} risk level: #{json["risk"]}",
                    details: json
                    })
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
