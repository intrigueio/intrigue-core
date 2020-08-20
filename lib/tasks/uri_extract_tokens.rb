module Intrigue
  module Task
  class UriExtractTokens  < BaseTask
  
    include Intrigue::Task::Web
  
    def self.metadata
      {
        :name => "uri_extract_tokens",
        :pretty_name => "URI Extract Tokens",
        :authors => ["jcran"],
        :description => "This task analyzes and extracts tokens and analytics ids from the page.",
        :references => [],
        :type => "discovery",
        :passive => false,
        :allowed_types => ["Uri"],
        :example_entities => [{"type" => "Uri", "details" => {"name" => "https://intrigue.io"}}],
        :allowed_options => [],
        :created_types => ["DnsRecord"]
      }
    end
  
    def run
      super
  
      # Go collect the page's contents
      uri = _get_entity_name
      contents = http_get_body(uri)
  
      unless contents
        _log_error "Unable to retrieve uri: #{uri}"
        return
      end
  
      ###
      ### Now, parse out all links and do analysis on the individual links
      ###
      patterns = Intrigue::Entity::UniqueToken.supported_token_types

      patterns.each do |p|

        if contents =~ p[:matcher]

          _log "matched: #{p[:matcher]}"

          # grab it 
          match_data = p[:matcher].match(contents) do |m|
            _log "Got: #{m[1]}"
            _create_entity "UniqueToken", "name" => "#{m[1]}"
          end
        
        else 
          _log "no match for: #{p[:matcher]}"

        end
      end
    end
  
  end
  end
  end
  