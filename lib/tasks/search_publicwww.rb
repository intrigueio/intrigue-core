module Intrigue
  module Task
  class SearchPublicWww < BaseTask

    def self.metadata
      {
        :name => "search_publicwww",
        :pretty_name => "Search PublicWWW",
        :authors => ["Anas Ben Salah", "jcran"],
        :description => "This task hits Publicwww website for listing URLs sharing the same Analytics Ids.",
        :references => [],
        :type => "discovery",
        :passive => true,
        :allowed_types => ["UniqueToken"],
        :example_entities => [{"type" => "UniqueToken", "details" => {"name" => "UA-61330992"}}],
        :allowed_options => [],
        :created_types => ["Uri"]
      }
    end

    ## Default method, subclasses must override this
    def run
      super

      entity_name = _get_entity_name

      # Make sure the key is set
      api_key = _get_task_config("publicwww_api_key")

      # special case google analytics, as we can find interesting things by not 
      # sending the last bit of the key
      if entity_name =~ /^ua-.*$/i
        entity_name = entity_name.split("-")[0..-2].join("-")
        _log "Dropping trailing part of google user agent: #{entity_name}"
      end


      # Craft the UniqueToken search URL to export
      query_url = "https://publicwww.com/websites/%22#{entity_name}-%22/?export=urls&key=#{api_key}"
      
      # Download the xport
      download = http_get_body(query_url)
      
      # read the file results
      download.split("\n").each do |found_url|
        _create_entity "Uri" , "name" => found_url
      end

    end

end
end
end
