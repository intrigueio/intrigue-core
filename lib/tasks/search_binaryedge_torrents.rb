module Intrigue
module Task
class SearchBinaryEdgeTorrents < BaseTask

  def self.metadata
    {
      :name => "search_binaryedge_torrents",
      :pretty_name => "Search BinaryEdge Torrent",
      :authors => ["Anas Ben Salah"],
      :description => "This task hits the BinaryEdge API for a given" +
        "IP, and tells us if the address has seen activity consistent with torrenting",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["IpAddress"],
      :example_entities => [
        {"type" => "IpAddress", "details" => {"name" => "1.1.1.1"}}
      ],
      :allowed_options => [
        {:name => "create_issues", :regex=> "boolean", :default => true },
      ],
      :created_types => []
    }
  end

  def run
    super

    entity_name = _get_entity_name

    # Work the magic
    search_ip_torrent entity_name

  end #end run


  def search_ip_torrent(entity_name)

    begin

      # Make sure the key is set
      api_key = _get_task_config("binary_edge_api_key")
      headers = { "X-Key" =>  "#{api_key}" }

      # Make the request
      uri = "https://api.binaryedge.io/v2/query/torrent/ip/#{entity_name}"
      json = JSON.parse(http_request(:get, uri, nil, headers).body)

      # TODO ... is there a better attribute to check?
      if json["title"] == "Not Found"
        _log "Not Found!"
        return
      else
        _log "Found!"
      end

      # TODO .... do we need to paginate this?
      json["events"].each do |t|
        ############################################
        ###      New Issue                      ###
        ###########################################
        _create_linked_issue("torrent_affiliated_ip",{
          detailed_description: "
            Ip Address: #{entity_name}:#{t["peer"]["port"]}
            Name: #{t["torrent"]["name"]}\n
            Source: #{t["torrent"]["source"]}\n
            Category: #{t["torrent"]["category"]}\n
            Subcategory: #{t["torrent"]["subcategory"]}",
          references: ["https://binaryedge.com/"],
          details: t
        })
      end

    rescue JSON::ParserError => e
      _log_error "Unable to parse JSON: #{e}"
    end
  end # end run

end
end
end
