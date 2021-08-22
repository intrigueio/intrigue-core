module Intrigue
  module Task
    class SearchLeakLookup < BaseTask
      def self.metadata
        {
          name: "search_leak_lookup",
          pretty_name: "Search Leak-Lookup",
          authors: ["adambakalar"],
          description: "This task hits the Leak Lookup API for leaked accounts.",
          references: ["https://leak-lookup.com/api"],
          type: "discovery",
          passive: true,
          allowed_types: ["EmailAddress", "IpAddress", "Domain"],
          example_entities: [
            { "type" => "EmailAddress", "details" => { "name" => "testing@intrigue.io" } },
            { "type" => "IpAddress", "details" => { "name" => "192.0.78.13" } },
            { "type" => "Domain", "details" => { "name" => "intrigue.io" } }
          ],
          allowed_options: [],
          created_types: []
        }
      end

      ## Default method, subclasses must override this
      def run
        super

        entity_name = _get_entity_name
        entity_type = _get_entity_type_string

        api_key = _get_task_config("leak_lookup_api_key")

        unless api_key
          _log_error "Unable to proceed, no API key for Leak Lookup provided."
          return
        end

        if entity_type == "EmailAddress"
          leak_lookup_entity_type = "email_address"

        elsif entity_type == "IpAddress"
          leak_lookup_entity_type = "ipaddress"

        elsif entity_type == "Domain"
          leak_lookup_entity_type = "domain"
        end

        # Search info construction
        search_uri = "https://leak-lookup.com/api/search"
        params = { key: api_key, type: leak_lookup_entity_type, query: entity_name }
        headers = {
          "Content-Type" => "application/x-www-form-urlencoded"
        }

        # Make the request
        response = _get_json_response(search_uri, params, headers)

        if response["message"] && response["error"] == "false"

          if response["message"].empty?
            _log "No findings for the supplied entity."
            return
          end

          public_api_key_proof_message = "No detailed breach data is shown when using public keys"

          response["message"].each do |result_key, result_value|

            _create_linked_issue("leaked_data", {
              name: "Entity found in Leak-Lookup (Public Breach Data)",
              source: result_key,
              proof: result_value.empty? ? public_api_key_proof_message : result_value,
              references: [
                { type: "description", uri: "https://leak-lookup.com"}
              ]
            })
          end

        elsif response["error"] == "true"
          _log_error "The Leak Lookup API returned the following error: #{response['message']}"
        end
      end

      def _get_json_response(uri, data, headers)
        begin
          response = http_post(uri, data, headers)

          # No idea if this is a Typhoeus::Request lib issue, or just a Leak-Lookup side one, but
          # we can encounter successful responses with empty bodies
          if (response.body).empty?
            _log_error "Got an HTTP response with an empty body from the Leak-Lookup service. Please run the task again."
            return
          end

          parsed_response = JSON.parse(response.body)

          _log "Got JSON: #{parsed_response}"
        rescue JSON::ParserError => e
          _log "Encountered error while parsing JSON: #{e}"
        end
        parsed_response
      end
    end
  end
end
