module Intrigue
module Task
class SearchRobtex < BaseTask
  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "threat/search_robtex",
      :pretty_name => "Threat Check - Search Robtex",
      :authors => ["jcran"],
      :description => "Use Robtex API to find detail on IpAddresses",
      :references => ["https://www.robtex.com/","https://market.mashape.com/robtex/robtex"],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["IpAddress"],
      :example_entities => [
        {"type" => "IpAddress", "details" => {"name" => "1.1.1.1"}}
      ],
      :allowed_options => [],
      :created_types => ["AsNumber", "DnsRecord", "NetBlock"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    #
    # This module currently uses the  Free API (rate limited / response limited)
    # https://freeapi.robtex.com/ipquery/#{search_ip}
    #
    # Note that a paid version (free up to 10k queries / month) of the API is available at:
    # https://market.mashape.com/robtex/robtex
    #

    # Check Robtex API & create entities from returned JSON
    search_ip = _get_entity_name
    search_uri = "https://freeapi.robtex.com/ipquery/#{search_ip}"

    begin
      details = JSON.parse(http_get_body(search_uri))
      _log "Got details: #{details}"

      #status
      #  Should be "ok"
      unless details["status"] == "ok"
        _log_error "Unable to continue"
        return
      end

      #act
      #  Active (forward) DNS
      if details["act"]
        details["act"].each do |forward_lookup|
          _create_entity "DnsRecord",{
            "name" => forward_lookup["o"],
            "time" => "#{Time.at(forward_lookup["t"])}"
          }
        end
      end

      #pas
      #  Passive (reverse) DNS
      if details["pas"]
        details["pas"].each do |reverse_lookup|
          _create_entity "DnsRecord",{
            "name" => reverse_lookup["o"],
            "time" => "#{Time.at(reverse_lookup["t"])}"
          }
        end
      end

      #pash
      #  Passive DNS history
      # TODO

      #acth
      #  Active DNS history
      # TODO

      #as
      # Autonomous System Number
      if details["as"]
        _create_entity "AsNumber",{
          "name" => "AS#{details["as"]}",
          "as_name" => details["asname"],
          "as_desc" => details["asdesc"]
        }
      end

      # Netblock
      #
      if details["bgproute"]
        _create_entity "NetBlock",{"name" => "#{details["bgproute"]}"}
      end

    rescue JSON::ParserError => e
      _log_error "Unable to get parsable response from #{search_uri}: #{e}"
    rescue StandardError => e
      _log_error "Error grabbing robtex details: #{e}"
    end


  end

end
end
end
