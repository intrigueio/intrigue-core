

class UriNomNomTask < BaseTask

  def metadata
    { :version => "1.0",
      :name => "uri_nomnom",
      :pretty_name => "URI NomNom",
      :authors => ["jcran"],
      :description => "This task uses an api to spider a site, creating relevant entities.",
      :references => [],
      :allowed_types => ["Uri"],
      :example_entities => [
        {:type => "Uri", :attributes => {:name => "http://www.intrigue.io"}}
      ],
      :allowed_options => [
        {:name => "depth_limit", :type => "Integer", :regex => "integer", :default => 2 },
      ],
      :created_types =>  ["DnsRecord", "EmailAddress", "File", "Info", "Person", "PhoneNumber" "SoftwarePackage"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    uri = _get_entity_attribute "name"

    #api_uri = "http://nomnom.api.intrigue.io/crawl"
    api_uri = "http://localhost:9393/crawl"

    resource = RestClient::Resource.new api_uri,
                                        :timeout => nil,
                                        :open_timeout => nil

    response = resource.post({ "key" => "intrigue",
                               "uri" => uri,
                               "depth" => 2 })

    begin
      result =  JSON.parse response
      result["entities"].each {|e| _create_entity(e["type"], e["attributes"]) }
    rescue JSON::ParserError
      @task_log.error "Something went horribly wrong server-side :("
      @task_log.error "Please report an error to support@intrigue.io"
    end

  end

end
