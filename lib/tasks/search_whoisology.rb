module Intrigue
module Task
class SearchWhoisology < BaseTask

  def self.metadata
    {
      :name => "search_whoisology",
      :pretty_name => "Search Whoisology",
      :authors => ["jcran"],
      :description => "This task hits the Whoisology API and finds matches based on the email specified on whois records.",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["Domain","DnsRecord", "EmailAddress", "UniqueKeyword"],
      :example_entities => [{"type" => "EmailAddress", "details" => {"name" => "intrigue.io"}}],
      :allowed_options => [],
      :created_types => ["DnsRecord","Info"]
    }
  end

  def search_whoisology_by_email(api_key, email_address)
    _log "Searching whoisology by email"
    begin 
      # Attach to the whoisology service & search
      whoisology = Whoisology::Api.new(api_key)

      # Run a PING to see if we have any results
      result = whoisology.ping "email", email_address
      _log "Got #{result}"
      _log "Got #{result["count"]} results for email search"
      return if result["count"].to_i == 0

      # do the actual search with the FLAT comman      
      result = whoisology.flat "email", email_address
      _log_good "Creating entities for #{result["count"]} results."
    
      if result["domains"]
        result["domains"].each {|d| 
          _create_entity "Domain", {"name" => d["domain_name"]}, "scoped" => true }
      else
        _log_error "No domains, do we have API credits?"
      end
    rescue RestClient::Forbidden => e 
      _log_error "Error when querying whoisology (forbidden)"
    end
  end

  def search_whoisology_by_keyword(api_key, keyword)
    _log "Searching whoisology by keyword"
    begin 
      # Attach to the whoisology service & search
      whoisology = Whoisology::Api.new(api_key)

      # Run a PING to see if we have any results
      result = whoisology.ping "organization", keyword
      _log "Got #{result}"
      _log "Got #{result["count"]} results for organizaiton search"
      return if result["count"].to_i == 0

      # do the actual search with the FLAT command
      result = whoisology.flat "organization", keyword
      _log_good "Creating entities for #{result["count"]} results."
    
      if result["domains"]
        result["domains"].each {|d| 
          _create_entity "Domain", {"name" => d["domain_name"]}, "scoped" => true }
      else
        _log_error "No domains, do we have API credits?"
      end
    rescue RestClient::Forbidden => e 
      _log_error "Error when querying whoisology (forbidden)"
    end
  end


  
  def run
    super

    begin
      # get values
      api_key = _get_task_config "whoisology_api_key"
      entity_name = _get_entity_name

      # make sure values are set
      unless entity_name
        # Something went wrong with the lookup?
        _log "Unable to get entity value"
        return
      end

      unless api_key
        _log_error "No api_key?"
        return
      end

      case _get_entity_type_string

        when "EmailAddress"
          
          search_whoisology_by_email api_key, entity_name

        when "DnsRecord", "Domain"

          ## When we have a Domain or DnsRecord, we need to do a lookup on the current record,
          ## grab the email address, and then do the search based on that email

          _log "Looking up contacts for domain #{entity_name}"
          begin
            # We're going to pull the domain's email address....
            whois = ::Whois::Client.new(:timeout => 20)
            answer = whois.lookup(entity_name)
            # Run through the contacts and pick the first one
            contact_emails = answer.parser.contacts.map{ |contact| contact.email }
            _log "Got contact_emails: #{contact_emails}"
          rescue Timeout::Error => e
            _log_error "Unable to lookup #{entity_name}... try a manual lookup"
            return nil
          rescue ::Whois::Error => e
            _log_error "Whois Exception #{e.class}: #{e.message}" 
            return nil
          rescue StandardError => e
            _log_error "Application Exception #{e.class}: #{e.message}"
          end

          contact_emails_unique = contact_emails.uniq
          contact_emails_unique.each { |email| search_whoisology_by_email api_key, email } 

        when "UniqueKeyword"
          search_whoisology_by_keyword api_key, entity_name
      end

    end

  end # end run()

end # end Class
end
end
