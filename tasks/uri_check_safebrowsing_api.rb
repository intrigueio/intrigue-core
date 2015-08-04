module Intrigue
class UriCheckSafebrowsingApi  < BaseTask

  def metadata
    {
      :name => "uri_check_safebrowsing_api",
      :pretty_name => "URI Check Safebrowsing Api",
      :authors => ["jcran"],
      :description => "Check a URI against the Google Safebrowsing (StopBadware) API",
      :references => [],
      :allowed_types => ["Uri"],
      :example_entities => [ {:type => "Uri", :attributes => {:name => "http://intrigue.io"}} ],
      :allowed_options => [],
      :created_types => ["Info"]
    }
  end

  def run
    super

    # Get the target URI
    target_uri = _get_entity_attribute("name")

    begin
      # Get the API Key & create a client
      api_key = _get_global_config "google_safebrowsing_lookup_key"
      @client = Client::Search::Google::SafebrowsingLookup.new(api_key)

      ### Run the lookup and print the response
      response_hash = @client.lookup target_uri

    # XXX - Handle a bug in the Safebrowsinglookup client where "error" can be thrown (fix this!)
    rescue NoMethodError => e
      @task_log.error "Unable to contact api, unknown error: #{e}"
      response_hash = {}
    end

    response_hash.each do |h,v|
      if v == "ok"
        @task_log.log "OK! #{h.to_s}"
      else
        _create_entity "Info", :name => "SafeBrowsing Uri", :uri => "#{h}", :content=> "#{v}"
        @task_log.log "Info: #{h}: #{v}"
      end
    end

  end

end
end
