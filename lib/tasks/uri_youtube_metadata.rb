module Intrigue
module Task
class UriYoutubeMetadata < BaseTask

  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "uri_youtube_metadata",
      :pretty_name => "URI Youtube Metadata",
      :authors => ["jcran"],
      :description => "This task downloads metadata and creates users from the metadata, given a youtube video Uri.",
      :references => [],
      :allowed_types => ["Uri"],
      :type => "discovery",
      :passive => true,
      :example_entities => [
        {"type" => "Uri", "details" => { "name" => "https://www.youtube.com/watch?v=ZPr-_21-xGQ" }}
      ],
      :allowed_options => [],
      :created_types =>  ["Info", "WebAccount"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super
    video_uri = _get_entity_name

    unless video_uri =~ /www\.youtube\.com\/watch/
      _log_error "This doesn't appear to be a valid youtube video uri."
      return nil
    end

    begin
      video_json = http_get_body "http://www.youtube.com/oembed?url=#{video_uri}&format=json"
      d = JSON.parse video_json
    
      if d["author_name"]
        _create_normalized_webaccount("youtube", d["author_name"], video_uri)
      end

    rescue JSON::ParserError
      _log_error "Unable to retrieve video metadata"
    end

  end

end
end
end
