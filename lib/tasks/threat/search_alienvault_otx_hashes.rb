module Intrigue
module Task
class SearchAlienvaultOtxHashes < BaseTask

   def self.metadata
    {
      :name => "threat/alienvault_otx_hashes",
      :pretty_name => "Threat Check - Search Alienvault OTX (Hash)",
      :authors => ["Anas Ben Salah"],
      :description => "This task searches AlienVault OTX via API and checks for information related to a FileHash",
      :references => ["https://otx.alienvault.com/api"],
      :type => "threat_check",
      :passive => true,
      :allowed_types => ["FileHash"],
      :example_entities => [{"type" => "FileHash", "details" => {"name" => "4fa5ecd96c3f8d90efe4db2ed4b3afd0"}}],
      :allowed_options => [],
      :created_types => ["Domain"]
    }
   end

  def run
    super

    # get entity details
    entity_name = _get_entity_name
    entity_type = _get_entity_type_string

    result = search_otx_by_hash entity_name

    # return if response is null
    if result["pulse_info"]["count"]== 0
      _log "No pulse info found, nothing to do!"
      return
    end

    #Create issue and pull out the malicious File and some related informations
    result["pulse_info"]["pulses"].each do |e|
      source = "Alienvault OTX"
      _create_linked_issue("suspicious_activity_detected",{
        name: "File detected as suspicious in #{source}",
        references: result["pulse_info"]["references"],
        description: "#{e["description"]}",
        proof: e
      })
    end

  end #end run

  def search_otx_by_hash hash
    # Make sure the key is set
    api_key = _get_task_config("otx_api_key")

    headers = { 'Accept': 'application/json', 'X-OTX-API-KEY': api_key }

    begin
      # get the initial response for the hash
      url = "https://otx.alienvault.com/api/v1/indicators/file/#{hash}/general"
      response = http_get_body("#{url}", nil, headers)
      result = JSON.parse(response)
    rescue JSON::ParserError => e
      _log_error "unable to parse json!"
    end
  result
  end #end search_hash

end # end Class
end
end
