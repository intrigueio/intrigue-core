module Intrigue
  module Task
  class SearchPublicWWWUniqueToken < BaseTask

    def self.metadata
      {
        :name => "search_publicwww_uniquetoken",
        :pretty_name => "Search Publicwww UniqueToken",
        :authors => ["Anas Ben Salah"],
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
      entity_type = _get_entity_type_string

      # Make sure the key is set
      api_key = _get_task_config("publicwww_api_key")

      # check the UniqueToken if it is a google analytics id
      if entity_name =~ /^UA-[\d\-]+$/i
        url = "https://publicwww.com/websites/%22#{entity_name}-%22/?export=urls&key=#{api_key}"
      # check the UniqueToken if it is a google google adsense id
      elsif entity_name =~ /^pub-\d+$/i
        url = "https://publicwww.com/websites/%22#{entity_name}%22/?export=urls&key=#{api_key}"
      else
        _log_error "Unsupported entity type"
      end


      # Download and store the file temporarily
      download = open(url)
      file='data/publicwww_uniqtoken_urls.txt'
      IO.copy_stream(download, file)
      # read the file results
      File.readlines(file).each do |url|
        create_related_urls url
      end
      # delete the temporarily file
      File.delete(file)

    end #end run

    #create entities of domains_related_to_same_analyticsid and AdSense
    def create_related_urls uri
      _create_entity "Uri" , "name" => uri
    end

end
end
end
