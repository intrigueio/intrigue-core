class SearchCorpwatchTask < BaseTask

  def metadata
    { :version => "1.0",
      :name => "search_edgar",
      :pretty_name => "Search EDGAR",
      :authors => ["jcran"],
      :description => "EDGAR Corporation Search",
      :references => [],
      :allowed_types => ["String", "Organization"],
      :example_entities => [{:type => "String", :attributes => {:name => "intrigue"}}],
      :allowed_options => [],
      :created_types => ["*"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    # Make sure the key is set
    raise "API KEY MISSING: corpwatch_api_key" unless $intrigue_config["corpwatch_api_key"]
    api_key = $intrigue_config['corpwatch_api_key']

    # Attach to the corpwatch service & search
    x = Client::Search::Corpwatch::ApiClient.new(api_key)
    corps = x.search(_get_entity_attribute "name")

    corps.each do |corp|

      # Create a new organization entity & attach a record
      _create_entity "Organization", {
        :name => corp.name,
        :data => corp.to_s
      }

      _create_entity "PhysicalLocation", {
        :name => corp.address,
        :address => corp.address,
        :state => corp.state,
        :country => corp.country
      }

    end
  end
end
