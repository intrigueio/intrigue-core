module Intrigue
  module Task
  module Enrich
  class UniqueToken < Intrigue::Task::BaseTask
  
    def self.metadata
      {
        :name => "enrich/unique_token",
        :pretty_name => "Enrich Unique Token",
        :authors => ["jcran"],
        :description => "Fills in details for a token (aalytics id or api key)",
        :references => [],
        :type => "enrichment",
        :passive => false,
        :allowed_types => ["UniqueToken"],
        :example_entities => [
          { "type" => "UniqueToken",
            "details" => {
              "name" => "UA-1234567890"
            }
          }
        ],
        :allowed_options => [],
        :created_types => []
      }
    end
  
    ## Default method, subclasses must override this
    def run
      _log "Enriching... unique token: #{_get_entity_name}"

      # create a linked issue if this token is known to be sensitive
      _create_linked_issue("leaked_token") if _get_entity_detail("sensitive")
    end
  
  end
  end
  end
  end