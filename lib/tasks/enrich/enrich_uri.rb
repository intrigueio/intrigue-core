module Intrigue
class EnrichUri < BaseTask
  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "enrich_uri",
      :pretty_name => "Enrich URI",
      :authors => ["jcran"],
      :description => "Sets the \"api\" detail, letting us know if this is an api endpoint.",
      :references => [],
      :type => "enrichment",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [{"type" => "Uri", "attributes" => {"name" => "https://intrigue.io"}}],
      :allowed_options => [],
      :created_types => []
    }
  end

  def run
    super
    # Grab the full response 2x
    uri = _get_entity_name

    api_enabled = check_api_endpoint(uri)
    #webdav_enabled = check_webdav_endpoint(uri)
    verbs_enabled = check_options_endpoint(uri)

    @entity.lock!
    @entity.update(:details => @entity.details.merge({
      "api" => api_enabled,
      "verbs" => verbs_enabled
    }))

  end

  def check_options_endpoint(uri)
    response = http_request(:options, uri)
    (response["allow"] || response["Allow"]) if response
  end

  def check_webdav_endpoint(uri)
    http_request :propfind, uri
  end


  def check_api_endpoint(uri)
    response = http_request :get, uri

    unless response
      _log_error "Unable to receive a response for #{uri}, bailing"
      return
    end

    return true if response.header['Content-Type'] =~ /application/

  false
  end

end
end
