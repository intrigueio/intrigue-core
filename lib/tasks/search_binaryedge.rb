module Intrigue
  module Task
  class SearchBinaryEdge < BaseTask

    def self.metadata
      {
        :name => "search_binaryedge",
        :pretty_name => "Search BinaryEdge",
        :authors => ["jcran","Anas Ben Salah"],
        :description => "This task hits the BinaryEdge API for a given IpAddress, DnsRecord or Domain, and " +
          "create new entities such as NetworkServices and Uri, as well as associated host details.",
        :references => [],
        :type => "discovery",
        :passive => true,
        :allowed_types => ["IpAddress", "DnsRecord", "Domain", "EmailAddress", "NetBlock"],
        :example_entities => [
          {"type" => "Domain", "details" => { "name" => "intrigue.io"}}
        ],
        :allowed_options => [],
        :created_types => ["NetworkService", "Uri", "DnsRecord"]
      }
    end

    ## Default method, subclasses must override this
    def run
      super

      entity_name = _get_entity_name
      entity_type = _get_entity_type_string

      # Make sure the key is set
      api_key = _get_task_config("binary_edge_api_key")

      if entity_type == "IpAddress"
        response = search_binaryedge_by_ip entity_name, api_key

        if response["events"]
          response["events"].each do |e|
            e["results"].each do |r|

              # create a network service for every result
              # saving the details off as extended details
              port = r["target"]["port"]
              proto = r["target"]["protocol"]
              be_details = {"extended_binaryedge" => e }
              _create_network_service_entity(@entity,port,proto, be_details)

              # this should be optional...
              #if port != "443"
              #  _create_issue({
              #    name: "#{entity_name}:#{port}  [Binary Edge]",
              #    type: "Malicious IP",
              #    severity: 3 ,
              #    status: "confirmed",
              #    description: "Port: #{e["port"]} || State:#{r["result"]["data"]["state"]} || Security issue:#{r["result"]["data"]["security"]}
              #    || Reason:#{r["result"]["data"]["reason"]} || ", #Running Service:#{r["result"]["data"]["service"]}"s
              #    details: json
              #  })
              #end

            end
          end
        end

      elsif entity_type == "Domain"
        # look for related eentities?
        dns_records = search_binaryedge_by_subdomain entity_name, api_key

        dns_records.each do |d|
          _create_entity "DnsRecord" , "name" => d
        end

        # also check for data leaks
        response = search_binaryedge_leaks_by_domain entity_name, api_key
        response["groups"].each do |t|
          # create issues if we found any
          _create_linked_issue("leaked_data",{
            proof: "#{t["count"]} accounts found related to #{entity_name} in #{t["leak"]}",
            detailed_description: "#{t["count"]} accounts found related to #{entity_name} in #{t["leak"]}",
            references:["https://binaryedge.com/",
            "https://askleo.com/account-involved-breach/"] ,
            details: t
          })
        end

      elsif entity_type == "EmailAddress"

        # checks for data leaks
        response = search_binaryedge_leaks_by_email_address entity_name, api_key

        if response["total"] == 0
          _log "No results found!"
          return
        end

        # create issues if we found any
        response["events"].each do |u|
          ############################################
          ###      Old Issue                      ###
          ###########################################
          # _create_issue({
          #    name: "Email Found in Data Leak #{u}",
          #    type: "leaked_account",
          #    severity: 3,
          #    status: "confirmed",
          #    detailed_description: "This Email has been found in this breach: #{u}, via BinaryEdge",
          #    references:"https://binaryedge.com/",
          #    details: u
          #  })
          ############################################
          ###      New Issue                      ###
          ###########################################
          _create_linked_issue("leaked_data",{
            proof: "This Email has been found in this breach: #{u}",
            name: "Email Found in Data Leak #{u}",
            type: "leaked_email",
            detailed_description: "This Email has been found in this breach: #{u}, via BinaryEdge",
            references:"https://binaryedge.com/",
            details: u
          })
        end

      elsif entity_type == "NetBlock"
        #do the right thing
        events = search_binaryedge_netblock(_get_entity_name, api_key, 0)
        events.each do |e|
          begin  
            port = e["target"]["port"]
            target = e["target"]["ip"]
            protocol = e["target"]["protocol"]
            _create_entity "NetworkService", {"name" => "#{target}:#{port}/#{protocol}"}
            
          rescue NoMethodError, KeyError
            # pass it on
            next
          end
        end
        
      else
        _log_error "Unsupported entity type"
      end

    end #end run

  end
end
end
