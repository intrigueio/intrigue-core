module Intrigue
  module Task
  class UriCheckRetirejs < BaseTask
  
    include Intrigue::Task::Browser
  
    def self.metadata
      {
        :name => "uri_check_retirejs",
        :pretty_name => "URI Check Retire.js",
        :authors => ["jcran"],
        :description => "This task checks a url against the retire.js databasee.",
        :references => [],
        :type => "discovery",
        :passive => false,
        :allowed_types => ["Uri"],
        :example_entities => [
          {"type" => "Uri", "details" => {"name" => "http://www.intrigue.io"}}
        ],
        :allowed_options => [],
        :created_types =>  []
      }
    end
  

    ###
    ### Data file formatting
    ###
=begin
  
	"retire-example": {
		"vulnerabilities" : [
			{
				"below" : "0.0.2",
				"severity" : "low",
				"identifiers" : {
					"CVE" : [ "CVE-XXXX-XXXX" ],
					"bug" : "1234",
					"summary" : "bug summary"
				},
				"info" : [ "http://github.com/eoftedal/retire.js/" ]
			}
		],
		"extractors" : {
			"func" : [ "retire.VERSION" ],
			"filename" : [ "retire-example-(§§version§§)(.min)?\\.js" ],
			"filecontent"	: [ "/\\*!? Retire-example v(§§version§§)" ],
			"hashes" : { "07f8b94c8d601a24a1914a1a92bec0e4fafda964" : "0.0.1" }
		}
	},
  
=end
    

    ## Default method, subclasses must override this
    def run
      super
  
      uri = _get_entity_name
  
      checks = JSON.parse(File.open("#{$intrigue_basedir}/data/retirejs.json", "r"))

      # make sure we can pull scripts
      require_enrichment
  
      # keep track of what's been found 
      found = []

      # now for each script that we have on the URI, go get it
      scripts = _get_entity_detail("scripts")
      scripts.each do |s|

        #_log "Working on script: #{s}"
        file_content = http_get_body s["uri"]

        # now traverse the list
        checks.each do |name, check| 
          #_log "Checking... #{name}"

          ###
          ### In order to be able to effectively regex, we need the version
          ###

          # get the content extractors
          content_extractors = check["extractors"]["filecontent"]
          next unless content_extractors
          
          # now for each extractor, add the version and test
          content_extractors.each do |fc|
            if file_content =~ /#{fc.gsub("§§version§§", version)}/
              _log "Got a match: #{name} #{fc}!"
            end
          end

        end
  
      end 

      _log "Found: #{found}"

      # now merge them together and set as the new details
      #_set_entity_detail("retirejs",found)
  
    end
  
  end
  end
  end
  