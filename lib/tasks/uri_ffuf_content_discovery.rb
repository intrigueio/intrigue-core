module Intrigue
  module Task
  class UriFfufContentDiscovery < BaseTask
  
    def self.metadata
      {
        :name => "uri_ffuf_content_discovery",
        :pretty_name => "URI Ffuf Content Discovery",
        :authors => ["jcran"],
        :description => "This task fuzzes a base-level uri for content.",
        :references => ["https://github.com/ffuf/ffuf"],
        :allowed_types => ["Uri"],
        :type => "discovery",
        :passive => false,
        :example_entities => [
          {"type" => "Uri", "details" => { "name" => "http://www.intrigue.io" }}
        ],
        :allowed_options => [],
        :created_types =>  ["Uri"]
      }
    end
  
    ## Default method, subclasses must override this
    def run
      super
  
      uri_string = _get_entity_name

      # Create a tempfile to store result
      temp_file = Tempfile.new("ffuf-#{rand(10000000)}")

      command = "ffuf -w #{$intrigue_basedir}/data/web_directories.list -u #{uri_string}/FUZZ -of json -o #{temp_file.path} 2>&1 >/dev/null"      
      _log "Running... #{command}"
      _unsafe_system command

      # read the file 
      temp_file.rewind
      json = JSON.parse(temp_file.read)
      json["results"].each do |r|
        _create_entity "Uri", { "name" => r["url"], "ffuf" => r }  
      end

      temp_file.unlink
      temp_file.close

    end
  
  end
  end
  end
  