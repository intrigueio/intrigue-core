class SearchShodanTask < BaseTask

  def metadata
    { :version => "1.0",
      :name => "search_shodan",
      :pretty_name => "Search Shodan",
      :authors => ["jcran"],
      :description => "Uses the SHODAN API to search for information",
      :references => [],
      :allowed_types => ["String", "IpAddress","NetSvc","DnsRecord", "DnsServer"],
      :example_entities => [
        {:type => "String", :attributes => {:name => "intrigue.io"}}
      ],
      :allowed_options => [],
      :created_types => ["IpAddress","NetSvc","Organization","PhysicalLocation"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    # Make sure the key is set
    raise "API KEY MISSING: shodan_api_key" unless $intrigue_config["shodan_api_key"]

    @client = Client::Search::Shodan::ApiClient.new($intrigue_config["shodan_api_key"])
    response = @client.search(_get_entity_attribute "name")

    # check to make sure we got a response.
    raise "ERROR: No response" unless response

    # Check to make sure we got results
    if response["matches"]

      @task_log.log "Found #{response["matches"].count} matches"

      # Go through the results
      response["matches"].each do |r|

        @task_log.log "* SHODAN Record *"

        #updated_at = DateTime.new(r["updated"])
        updated_at = DateTime.now

        #
        # Create a host record
        #
        @task_log.log "IP: #{r["ip"]}"
        host = _create_entity("IpAddress",{
          :name => "#{r["ip"]}",
          :age => "#{updated_at}"
        }) if r["ip"]

        #
        # Create a DNS record for all hostnames
        #
        r["hostnames"].each do |h|
          @task_log.log "Hostname: #{h}"
          _create_entity("DnsRecord",{ :name => "#{h}", :age => "#{updated_at}" })
        end

        #
        # Create a netsvc
        #
        @task_log.log "Port: #{r["port"]}"

        port = _create_entity("NetSvc",{
          :name => "#{host.attributes[:name]}:#{r["port"]}/tcp",
          :proto => "tcp",
          :port_num => r["port"],
          :fingerprint => r["data"],
          :age => "#{updated_at}"
        }) if r["port"]

        #
        # Create an organization
        #
        @task_log.log "Org: #{r["org"]}"
        org = _create_entity("Organization",{
          :name => "#{r["org"]}",
          :age => "#{updated_at}"
        }) if r["org"]

        #
        # Create a PhysicalLocation
        #
        @task_log.log "Location: #{r["postal_code"]}"
        location = _create_entity("PhysicalLocation",{
          :name => "#{r["latitude"]} / #{r["longitude"]}",
          :zip => "#{r["postal_code"]}",
          :state => "#{r["region_name"]}",
          :country => "#{r["country_name"]}",
          :latitude => "#{r["latitude"]}",
          :longitude => "#{r["longitude"]}",
          :age => "#{updated_at}"
        }) if r["country_name"]


        @task_log.log "Port: #{r["port"]}"
        @task_log.log "Port Data: #{r["data"]}"
        @task_log.log "Country: #{r["country_name"]}"
        @task_log.log "Country Code: #{r["country_code"]}"
        @task_log.log "Region Name: #{r["region_name"]}"
        @task_log.log "Area Code: #{r["area_code"]}"
        @task_log.log "DMA Code: #{r["dma_code"]}"
        @task_log.log "Postal Code: #{r["postal_code"]}"
        @task_log.log "Org: #{r["org"]}"

      end
    end
  end

end
