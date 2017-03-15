require 'whoisology'

module Intrigue
class SearchWhoisologyTask < BaseTask

  def self.metadata
    {
      :name => "search_whoisology",
      :pretty_name => "Search Whoisology",
      :authors => ["jcran"],
      :description => "This task hits the Whoisology API and finds matches",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["EmailAddress"],
      :example_entities => [{"type" => "String", "attributes" => {"name" => "intrigue.io"}}],
      :allowed_options => [],
      :created_types => ["Host","Info"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    begin

      # Make sure the key is set
      api_key = _get_global_config "whoisology_api_key"
      entity_name = _get_entity_name

      case _get_entity_type
        when "EmailAddress"
          entity_type = "email"
          _log "Got entity type #{entity_type}"
      end

      unless api_key
        _log_error "No api_key?"
        return
      end

      # Attach to the whoisology service & search
      whoisology = Whoisology::Api.new(api_key)

      # Run a PING to see if we have any results
      result = whoisology.ping entity_type, entity_name
      _log "Got #{result}"
      _log "Got #{result["count"]} results"
      return if result["count"].to_i == 0

      # do the actual search with the FLAT command
      result = whoisology.flat entity_type, entity_name

      _log_good "Creating entities for #{result["count"]} results."
      if result["domains"]
        result["domains"].each {|d| _create_entity "Host", {"name" => d["domain_name"]} }
      else
        _log_error "No domains, do we have API credits?"
      end

    rescue RuntimeError => e
      _log_error "Runtime error: #{e.inspect}"
    end

  end # end run()

end # end Class
end
