module Intrigue
  module Task
  module Enrich
  class FileHash < Intrigue::Task::BaseTask
  
    def self.metadata
      {
        :name => "enrich/file_hash",
        :pretty_name => "Enrich FileHash",
        :authors => ["jcran"],
        :description => "Fills in details for an FileHash",
        :references => [],
        :allowed_types => ["FileHash"],
        :type => "enrichment",
        :passive => true,
        :example_entities => [
          {"type" => "FileHash", "details" => {"name" => "c2c30b3a287d82f88753c85cfb11ec9eb1466bad"}}],
        :allowed_options => [],
        :created_types => ["Domain"]
      }
    end
  
    def run
  
      file_hash = _get_entity_name.strip
      
      # determine the type based on regex 
      method = Intrigue::Entity::FileHash.supported_hash_types.find{|x| file_hash.match(x[:regex]) }
      if method
        our_type = method[:type]
      else 
        our_type = "unknown"
      end

      # save the hash type
      _set_entity_detail("hash_type", our_type)
      
    end
  
  end
  end
  end
  end