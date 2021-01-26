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
      _log "Checking for #{patterns.count} patterns"

      patterns.each do |p|

        # use matcher if it exists, but fall back to regex
        pattern = p["matcher"] || p["regex"]

        # if we're handed a string, convert it to a regex
        pattern = Regexp.new(pattern) unless pattern.kind_of? Regexp
        
        if contents =~ pattern
          _log "Matched: #{pattern}"
          # grab it 
          match_data = pattern.match(contents) do |m|
            _log "Got: #{m[1]}"
            _create_entity "UniqueToken", "name" => "#{m[1]}"
          end
        else 
          _log "No match for: #{pattern}"
        end

      end
    end
  
  end
  end
  end
  