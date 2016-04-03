module Intrigue
class SearchPiplTask < BaseTask

  def metadata
    {
      :name => "search_pipl",
      :pretty_name => "Search Pipl",
      :authors => ["jcran"],
      :description => "Use the Pipl API to search for entities",
      :references => [],
      :allowed_types => ["EmailAddress", "PhoneNumber", "String", "Person", "WebAccount"],
      :example_entities => [{"type" => "String", "attributes" => {"name" => "intrigue"}}],
      :allowed_options => [],
      :created_types => ["WebAccount","Uri"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    # Get the API Key
    api_key = _get_global_config "pipl_api_key"

    unless api_key
      @task_result.logger.log_error "No api_key?"
      return
    end


    @pipl_client = Client::Search::Pipl::ApiClient.new(api_key)

    if @entity.type_string == "EmailAddress"
      response = @pipl_client.search :email, _get_entity_attribute("name")
    elsif @entity.type_string == "PhoneNumber"
      response = @pipl_client.search :phone, _get_entity_attribute("name")
    elsif @entity.type_string == "Person"
      response = @pipl_client.search :name, _get_entity_attribute("name")
    else
      response = @pipl_client.search :username, _get_entity_attribute("name")
    end

    # We need to make sure that we got a response
    # because pipl will just send us a false if we get
    # the key wrong (ie, the api key hasn't been configured)
    unless response
      @task_result.logger.log_error "Got no response from Pipl. Are you sure your API key is correct?"
      return
    end

    if response["error"]
      @task_result.logger.log_error "Got error from pipl client: #{response["error"]}"
      return
    end

    ###
    #  The person object in the response holds all the information available on the person you were searching.
    #  It's returned only when your query parameters are unique enough and lead only to one possible person.
    #
    #  Here's a query that leads to one possible person and therefore has a person object in the response:
    #
    #  http://api.pipl.com/search/v3/json/?email=cartman@gmail.com&key=samplekey&pretty=true
    #
    #  Here's a query that leads to many different people and therefore doesn't have a person object in the response:
    #
    #  http://api.pipl.com/search/v3/json/?first_name=Jane&last_name=Brown&country=US&key=samplekey& pretty=true
    #  records
    #
    #  A list of records results each with full/partial match to your query parameters, a query for Eric Cartman from Colorado US might also return records with Eric Cartman from US (without Colorado).
    #
    #  The @query_params_match attribute of each record object helps you differentiate between records with full match to your query parameters and record with partial match.
    #
    #  The @query_person_match attribute of each record object tells you the likelihood that this record object holds data about the person that's represented by your query.
    #
    #  suggested_searches
    #
    #  When your query isn't focused enough and can't be matched to a specific person you'll get here a list of records, each holds data for a more detailed query.
    #
    #  Running the suggested search in a person object will help you zoom-in on the right person.
    #
    #  http://api.pipl.com/search/v3/json/?first_name=Eric&last_name=Cartman&key=samplekey&pretty=true
    ###

    @task_result.logger.log "Found #{response["@available_records"]} records"
    @task_result.logger.log "Parsing #{response["@records_count"]} records"

    #
    # First, handle the rare? case of a single person record associated with the query
    #
    if response["person"]

      if response["person"]["names"]

        @task_result.logger.log_good "Found a person! This indicates there's a single person record in pipl for this query."

        _create_entity "Person", "name" => "#{response["person"]["names"].first["display"]}"

        # Parse up the response sources
        response["person"]["sources"].each do |source|
          _create_entity "WebAccount", {
            "domain" => source["domain"],
            "uri" => source["url"],
            "name" => "#{source["name"]} #{source["domain"]}"
          }
        end
      end
    end

    #
    # First, handle the rare? case of a single person record associated with the query
    #
    if response["possible_persons"]
      response["possible_persons"].each do |pp|
        next unless pp["names"]
        pp["names"].each do |name|
          _create_entity("Person", { "name" => name["display"] })
        end
      end
    end


    #
    # Now, handle the (less rare?) case of a multiple associated records
    #
    if response["records"]

      response["records"].each do |record|

        # source
        # names
        # addresses
        # jobs
        # educations
        # images
        # usernames
        # related_urls
        # tags

        if record["source"]["domain"]
          _create_entity "WebAccount",
            "domain" => record["source"]["domain"],
            "name" => "#{record["source"]["url"].split("/").last} #{record["source"]["domain"]}",
            "uri" => record["source"]["url"]
        end

        #_create_entity "Person", :name => record["names"]["display"]
      end
    end

    @task_result.logger.log "FULL RESPONSE:"
    @task_result.logger.log "#{response.to_json.to_s}"

  end
=begin
    if response["records"]
      # Parse up the response records
      response["records"].each do |record|
        @task_result.logger.log "Record: #{record.to_s}\n"

        _create_entity "Uri", {
          "name" => record["source"]["name"],
          "confidence" => record["@query_person_match"],
          "uri" => record["source"]["url"],
          "comment" => record["content"] ? record["content"].map{|x| x.to_s.join(" ")} : ""
        }

        if record["usernames"]
          record["usernames"].each do |username|
            _create_entity "Webaccount", { "name" => username["content"].downcase, "domain" => record[""] }
          end
        end
      end
    end
=end
end
end
