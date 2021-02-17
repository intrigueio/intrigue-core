module Intrigue
module Task
class SearchBinaryEdgeOpenDataBase < BaseTask

  def self.metadata
    {
      :name => "search_binaryedge_open_database",
      :pretty_name => "Search BinaryEdge Open Databases",
      :authors => ["Anas Ben Salah"],
      :description => "This task hits the BinaryEdge API, looking for for open databases and creating the entities",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["String"],
      :example_entities => [
        {"type" => "String", "details" => {"name" => "unused option"}}
      ],
      :allowed_options => [
        {:name => "elastic", :regex => "boolean", :default => true },
        {:name => "mongodb",:regex => "boolean", :default => false },
        {:name => "couchdb", :regex => "boolean", :default => false },
        {:name => "rsync",:regex => "boolean", :default => false },
        {:name => "sonarqube", :regex => "boolean", :default => false },
        {:name => "jenkins",:regex => "boolean", :default => false },
        {:name => "gitlab", :regex => "boolean", :default => false },
        {:name => "kibana",:regex => "boolean", :default => false },
        {:name => "listing", :regex => "boolean", :default => false },
        {:name => "cassandra",:regex => "boolean", :default => false },
        {:name => "rethink",:regex => "boolean", :default => false },
        {:name => "first_page",:regex => "integer", :default => 1 },
        {:name => "last_page",:regex => "integer", :default => 20 }
      ],
      :created_types => []
    }
  end

  ## Default method, subclasses must override this,
  def run
    super

    # get options
    opt_elastic = _get_option("elastic")
    opt_mongodb = _get_option("mongodb")
    opt_couchdb = _get_option("couchdb")
    opt_rsync = _get_option("rsync")
    opt_sonarqube = _get_option("sonarqube")
    opt_jenkins = _get_option("jenkins")
    opt_gitlab = _get_option("gitlab")
    opt_kibana = _get_option("kibana")
    #opt_listing = _get_option("listing")
    opt_cassandra = _get_option("cassandra")
    opt_rethink = _get_option("rethink")

    # Set the range of research
    first_page = _get_option("first_page") || 1
    last_page = _get_option("last_page") || 20

    range = first_page..last_page

    elastic_query = "type:%22elasticsearch%22"
    mongodb_query = "type:%22mongodb%22"
    couchdb_query = "product:%22couchdb%22"
    rsync_query = "rsync port:%22873%22"
    sonarqube_query = "%22Title: SonarQube%22"
    jenkins_query = "%22Dashboard [Jenkins]%22"
    gitlab_query = "%22Sign in GitLab%22"
    kibana_query = "product:%22kibana%22"
    listing_query = '%22Index of /%22'
    cassandra_query = "type:%22cassandra%22"
    rethink_query = "type:%22rethinkdb%22"

    entity_name = _get_entity_name
    entity_type = _get_entity_type_string

    db_source = nil

    # Make sure the key is set
    api_key = _get_task_config("binary_edge_api_key")
    
    # Set the headers
    headers = { "X-Key" =>  "#{api_key}" }

    if opt_elastic == true
      query = elastic_query
	    range.each do |page_num|
   	    result = search_binaryedge_string_query(query,headers,entity_name,page_num)
        check_elastic_results(result)
      end
    end

    if opt_kibana == true
      query = kibana_query
	    range.each do |page_num|
   	    result = search_binaryedge_string_query(query,headers,entity_name,page_num)
        check_kibana_results(result)
      end
    end

    if opt_rsync == true
      query = rsync_query
      range.each do |page_num|
        result = search_binaryedge_string_query(query,headers,entity_name,page_num)
        check_rsync_results(result)
      end
    end

    if opt_jenkins == true
      query = jenkins_query
      range.each do |page_num|
        result = search_binaryedge_string_query(query,headers,entity_name,page_num)
        check_jenkins_results(result)
      end
    end

    if opt_gitlab == true
      query = gitlab_query
      range.each do |page_num|
        result = search_binaryedge_string_query(query,headers,entity_name,page_num)
        check_gitlab_results(result)
      end
    end

    if opt_sonarqube == true
      query = sonarqube_query
      range.each do |page_num|
        result = search_binaryedge_string_query(query,headers,entity_name,page_num)
        check_sonarqube_results(result)
      end
    end

    if opt_mongodb == true
      query = mongodb_query
      range.each do |page_num|
        result = search_binaryedge_string_query(query,headers,entity_name,page_num)
        check_mongodb(result)
      end
    end

    if opt_cassandra == true
      query = cassandra_query
      range.each do |page_num|
        result = search_binaryedge_string_query(query,headers,entity_name,page_num)
        check_cassandra_results(result)
      end
    end

    if opt_couchdb == true
      query = couchdb_query
      range.each do |page_num|
        result = search_binaryedge_string_query(query,headers,entity_name,page_num)
        check_couchdb_results(result)
      end
    end

    if opt_rethink == true
      query = rethink_query
      range.each do |page_num|
        result = search_binaryedge_string_query(query,headers,entity_name,page_num)
        check_rethinkdb_results(result)
      end
    end

  end

  # end
end
end
end
