module Intrigue
module Task
class SearchBinaryedgeRiskScore < BaseTask

  def self.metadata
    {
      :name => "search_binaryedge_risk_score",
      :pretty_name => "Search BinaryEdge Risk Score",
      :authors => ["Anas Ben Salah"],
      :description => "This task hits the BinaryEdge API and provides " +
                      "a risk score detail for a given IPAddress. It can optionally " + 
                      "create an issue for high risk IPs.", 
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["IpAddress"],
      :example_entities => [
        {"type" => "IpAddress", "details" => {"name" => "1.1.1.1"}}
      ],
      :allowed_options => [
        {:name => "create_issue", :regex=> "boolean", :default => true },
        {:name => "create_issue_greater_than_sev", :regex=> "integer", :default => 3 },
      ],
      :created_types => []
    }
  end

  def run
    super
    # Work the magic
    search_ip_score _get_entity_name
  end 

  def search_ip_score(entity_name)
  
    begin
      # Make sure the key is set
      api_key = _get_task_config("binary_edge_api_key")
      headers = {"X-Key" =>  "#{api_key}" }

      uri = "https://api.binaryedge.io/v2/query/score/ip/#{entity_name}"
      result = JSON.parse(http_request(:get, uri, nil, headers).body)

      if result["normalized_ip_score"] == 0
        _log "Unable to find ip address or no score"
        return 
      end

      # Normalize the score
      score = result["normalized_ip_score"]
      if score < 20 && score > 0
        calculated_sev = 5
      elsif score < 40 && score > 21
        calculated_sev = 4
      elsif score < 60 && score > 41
        calculated_sev = 3
      elsif score < 80 && score > 61
        calculated_sev = 2
      elsif score > 80
        calculated_sev = 1
      end

      if _get_option("create_issue") && calculated_sev > _get_option("create_issue_greater_than_sev")
        _create_issue({
          name: "High Risk Asset in BinaryEdge",
          type: "binaryedge_score",
          severity: calculated_sev,
          status: "confirmed",
          description: "
            Overall score:#{result["normalized_ip_score"]} || Detailed IP Score: Cve: #{result["normalized_ip_score_detailed"]["cve"]}\n
            Attack Surface: #{result["normalized_ip_score_detailed"]["attack_surface"]}\n
            Encryption: #{result["normalized_ip_score_detailed"]["encryption"]}\n
            Remote management service: #{result["normalized_ip_score_detailed"]["rms"]}\n
            Storage: #{result["normalized_ip_score_detailed"]["storage"]}\n
            Web: #{result["normalized_ip_score_detailed"]["web"]}\n
            Torrent: #{result["normalized_ip_score_detailed"]["torrents"]} ",
          references: ["https://binaryedge.com/"],
          details: result
        })
      else
        _log "Issue creation disabled for severity #{calculated_sev} asset"
      end

    rescue JSON::ParserError => e
      _log_error "Unable to parse JSON: #{e}"
    end
  end # end search_ip_score

end
end
end
