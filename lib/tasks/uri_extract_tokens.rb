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
        :created_types => ["UniqueToken"]
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
      _log "Checking for #{patterns.count} patterns"

      patterns.each do |p|

        pattern = p["regex"] || p[:regex]

        unless pattern
          _log_error "unable to use this pattern: #{p}"
          next
        end

        # if we're handed a string, convert it to a regex
        pattern = Regexp.new(pattern) unless pattern.kind_of? Regexp

        if contents =~ pattern
          _log "Matched: #{pattern}"
          # grab it 
          pattern.match(contents) do |m|
            # the last matched group will always be the actual token
            _log "Got: #{m[-1]}"
           _create_entity "UniqueToken", {"name" => "#{m[-1]}", "provider" => p["provider"] || p[:provider] , "snippet" => pattern.match(contents)}
          end
        else 
          _log "No match for: #{pattern}"
        end

      end
    end
  
  end
  end
end
  