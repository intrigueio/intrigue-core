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
      :allowed_types => ["EmailAddress", "Host"],
      :example_entities => [{"type" => "Host", "attributes" => {"name" => "intrigue.io"}}],
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

      case _get_entity_type_string

        when "EmailAddress"
          entity_type = "email"

        when "Host"

          ## When we have a host, we need to do a lookup on the current record,
          ## grab the email address, and then do the search based on that email

          _log "Looking up contacts for domain"
          begin
            # We're going to pull the domain's email address....
            whois = Whois::Client.new(:timeout => 20)
            answer = whois.lookup(entity_name)
            # Run through the contacts and pick the first one
            contact_emails = answer.parser.contacts.map{ |contact| contact.email }
            _log "Got contact_emails: #{contact_emails}"
          rescue Timeout::Error => e
            _log_error "Unable to lookup #{entity_name}... try a manual lookup"
            return nil
          end

          entity_name = contact_emails.first
          entity_type = "email"
      end

      _log "Got entity: #{entity_type} #{entity_name}"

      unless entity_name
        # Something went wrong with the lookup?
        _log "Unable to get a current email address"
        return
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
