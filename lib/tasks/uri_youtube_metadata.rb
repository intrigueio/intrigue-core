module Intrigue
class UriYoutubeMetadata < BaseTask

  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "uri_youtube_metadata",
      :pretty_name => "URI Youtube Metadata",
      :authors => ["jcran"],
      :description => "This task downloads metadata, given a youtube video Uri.",
      :references => [],
      :allowed_types => ["Uri"],
      :type => "discovery",
      :passive => true,
      :example_entities => [
        {"type" => "Uri", "attributes" => { "name" => "https://www.youtube.com/watch?v=ZPr-_21-xGQ" }}
      ],
      :allowed_options => [],
      :created_types =>  ["Info"]
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
      attributes = JSON.parse video_json
      _create_entity "Info", attributes.merge({"name" => "YouTube Video: #{attributes["title"]}"})

      if attributes["author_name"]
        _create_entity "WebAccount", {
          "name" => attributes["author_name"],
          "domain" => "youtube.com",
          "uri" => video_uri
        }
      end

    rescue JSON::ParserError
      _log_error "Unable to retrieve video metadata"
    end

  end

end
end
