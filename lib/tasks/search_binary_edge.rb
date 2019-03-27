module Intrigue
module Task
class SearchBinaryEdge < BaseTask

  def self.metadata
    {
      :name => "search_binary_edge",
      :pretty_name => "Search Binary Edge",
      :authors => ["jcran"],
      :description => "This task hits the Binary Edge API for a given IpAddress",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["IpAddress"],
      :example_entities => [{"type" => "IpAddress", "details" => {"name" => "8.8.8.8"}}],
      :allowed_options => [],
      :created_types => ["Uri"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    # Make sure the key is set
    api_key = _get_task_config("binary_edge_api_key")

    ip_address = _get_entity_name
    uri = "https://api.binaryedge.io/v2/query/ip/#{ip_address}"
    headers = {"X-Key" =>  "#{api_key}" }

    begin 
      json = JSON.parse(http_request(:get, uri, nil, headers).body)
      
      #_log_debug "Got JSON: #{JSON.pretty_generate(json)}"

      if json["events"]
        json["events"].each do |e|

          e["results"].each do |r|
            _log "result: #{r}"

            # Example:
            # {"target"=>{  "protocol"=>"tcp", "ip"=>"8.8.8.8", "port"=>53 }, 
            #                "result"=>{"data"=>{"state"=>{"state"=>"open"}, 
            #                    # "service"=>{"name"=>"domain", "method"=>"table_default", 
            #                    # "banner"=>"\\x00\\x1e\\x00\\x06\\x81\\x82\\x00\\x01\\x00\\x00\\x00\\x00\\x00\\x00\\x07version\\x04bind\\x00\\x00\\x10\\x00\\x03"}}}, 
            #                    # "origin"=>{"module"=>"grabber", "ts"=>1551579923157, "country"=>"us", "port"=>39906, "ip"=>"45.79.13.120", "type"=>"service-simple"}}

            _create_network_service_entity(@entity, r["target"]["port"],
                r["target"]["protocol"], {"binary_edge" => e}) 
          end
        end
      end    
    rescue JSON::ParserError => e
      _log_error "Unable to parse JSON: #{e}"
    end
  end # end run

end
end
end
