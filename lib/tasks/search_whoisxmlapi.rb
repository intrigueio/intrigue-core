module Intrigue
    module Task
    class WhoisXmlApi < BaseTask
      include Intrigue::Task::Web
    
      def self.metadata
        {
          :name => "search_whoisxmlapi",
          :pretty_name => "Search WhoisXMLAPI (Reverse Whois)",
          :authors => ["shpendk"],
          :description => "This task hits the WhoisXMLAPI reverse whois API and returns records that match the given email or keywoard",
          :references => ["https://reverse-whois.whoisxmlapi.com/api/documentation/making-requests"],
          :type => "discovery",
          :passive => true,
          :allowed_types => ["Domain", "EmailAddress", "Organization", "Person", "UniqueKeyword"],
          :example_entities => [ {"type" => "Organization", "details" => {"name" => "Intrigue Corp"}} ],
          :allowed_options => [
          #  {:name => "exclude_term", :regex => "alpha_numeric" , :default => "" }
          ],
          :created_types => ["Domain"]
        }
      end
    
      def run
        super
        
        uri = "https://reverse-whois.whoisxmlapi.com/api/v2"
        search_string = _get_entity_name
        api_key =  _get_task_config "whoisxmlapi_api_key"
    
        # prepare headers
        headers = { 'X-Authentication-Token': "#{api_key}" }
        
        # perpare search terms
        search = {"include": ["\"#{search_string}\""]}
        #if exclude_term != nil
        #    search["exclude"] = [exclude_term]
        #end

        #prepare post body
        body = {
          "searchType": "historic",
          "mode": "purchase",
          "punycode": true,
          "basicSearchTerms": search
        }
        
        _log "Searching whoisxmlapi historic and current database."
        res = http_request :post , uri, nil, headers, body.to_json, true, 60 # setting timeout to 60 seconds since this request takes a while

        if res.return_code == :operation_timedout
          _log_error "Request timed out after 60 seconds. Try again later."
          return
        end
        
        # parse response json
        res_json = JSON.parse(res.body)
        _log "Received  #{res_json["domainsCount"]} domains. Creating entities."
        
        # check to ensure we actually got a response
        unless res_json["domainsList"]
          _log_error "Did not receive any domains, returning early"
          return 
        end

        # create entities
        res_json["domainsList"].each do |domain|
          _create_entity "Domain", {"name" => domain, "scoped" => true }
        end

      end
    
    end
    end
    end
    