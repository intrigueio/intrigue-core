require 'digest'

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

    response_data = http_get_body uri
    response_data_hash = Digest::SHA256.base64digest(response_data) if response_data

    api_enabled = check_api_endpoint(uri)
    #webdav_enabled = check_webdav_endpoint(uri)
    verbs_enabled = check_options_endpoint(uri)

    @entity.lock!
    @entity.update(:details => @entity.details.merge({
      "api" => api_enabled,
      "verbs" => verbs_enabled,
      "response_data_hash" => response_data_hash,
      "response_data" => response_data
    }))

    # Check for other entities with this same response hash
    if response_data_hash
      Intrigue::Model::Entity.scope_by_project_and_type_and_detail_value(@entity.project.name,"Uri","response_data_hash", response_data_hash).each do |e|
        _log "Checking for Uri with detail: 'response_data_hash' == #{response_data_hash}"
        next if @entity.id == e.id

        _log "Attaching entity: #{e} to #{@entity}"
        @entity.add_alias e
        @entity.save

        _log "Attaching entity: #{@entity} to #{e}"
        e.add_alias @entity
        e.save
      end
    end
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
