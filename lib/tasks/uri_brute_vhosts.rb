module Intrigue
  module Task
  class UriBruteVhosts < BaseTask
  
    include Intrigue::Task::Data
    include Intrigue::Task::Web
  
    def self.metadata
      {
        :name => "uri_brute_vhosts",
        :pretty_name => "URI Bruteforce Vhosts",
        :authors => ["jcran", "jobertabma"],
        :description => "Bruteforce vhosts for a given URI.",
        :references => [],
        :type => "discovery",
        :passive => false,
        :allowed_types => ["Uri"],
        :example_entities => [ {"type" => "Uri", "details" => {"name" => "http://intrigue.io"}} ],
        :allowed_options => [ 
          {:name => "user_list", :regex => "alpha_numeric_list", :default => [] },
          {:name => "skip_codes", :regex => "alpha_numeric_list", :default => ["403", "530"] } 
        ],
        :created_types => ["Uri"]
      }
    end
  
    def run
      super
  
      # Get options
      uri = _get_entity_name

      user_list = _get_option("user_list")
      user_list = user_list.split(",") unless user_list.kind_of? Array
      skip_codes = _get_option("skip_codes")
  
      hostname = URI.parse(uri).hostname
      default_vhosts = [  "www.%s", "dev.%s", "local", "localhost", "status.%s", "status", 
                          "staging.%s", "staging", "development", "development.%s", "uat", 
                          "uat.%s", "%s", "beta", "beta.%s", "secure", "secure.%s", "mobile", 
                          "mobile.%s", "127.0.0.1", "m.%s", "m", "admin", "admin.%s", "old", 
                          "old.%s", "v1.%s", "v1", "v2.%s", "v2", "v3.%s", "v3", "alpha", 
                          "alpha.%s"].map{|x| x.gsub("%s", "#{hostname}")}

      # Pull our list from a file if it's set
      if user_list.length > 0
        brute_list = default_vhosts.concat(user_list.map {|x| {:username => x.split(":").first, :password => x.split(":").last } })
      else
        brute_list = default_vhosts
      end
  
      _log "brute_list: #{brute_list}"
  
      default_response = http_request(:get, uri)
      _log "Got default response code: #{default_response.code}"

      missing_response = http_request(:get, "#{uri}/#{rand(1000000000)}")
      _log "Got missing response code: #{missing_response.code}"

      # check the various vhosts
      brute_list.each do |b|
        headers = { "Host" => b } 
        response = http_request(:get, uri, nil, headers)
        if response.code != missing_response && !skip_codes.include?(response.code)
          _log_good "Hit! #{uri} with Host: #{b}, response code: #{response.code}" 
        end
      end

    end
  
  end
  end
  end
  