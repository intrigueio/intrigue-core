module Intrigue
module Task
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
      :example_entities => [{"type" => "Uri", "details" => {"name" => "https://intrigue.io"}}],
      :allowed_options => [],
      :created_types => []
    }
  end

  def run
    super

    uri = _get_entity_name

    # Grab the full response
    response = http_request :get, uri

    unless response && response.body
      _log_error "Unable to receive a response for #{uri}, bailing"
      return
    end

    response_data = response.body.encode('UTF-8', {:invalid => :replace, :undef => :replace, :replace => '?'})
    response_data_hash = Digest::SHA256.base64digest(response_data) if response_data

    # we can check the existing response, so send that
    api_enabled = check_api_endpoint(response)

    # we can check the existing response, so send that
    contains_forms = check_forms(response_data)

    # we'll need to make another request
    verbs_enabled = check_options_endpoint(uri)

    # we'll need to make another request
    #webdav_enabled = check_webdav_endpoint(uri)

    new_details = @entity.details.merge({
      "api" => api_enabled,
      "verbs" => verbs_enabled,
      "forms" => contains_forms,
      "response_data_hash" => response_data_hash,
      "response_data" => response_data
    })

    @entity.set_details(new_details)

    # Check for other entities with this same response hash
    if response_data_hash
      Intrigue::Model::Entity.scope_by_project_and_type_and_detail_value(@entity.project.name,"Uri","response_data_hash", response_data_hash).each do |e|
        _log "Checking for Uri with detail: 'response_data_hash' == #{response_data_hash}"
        next if @entity.id == e.id

        _log "Attaching entity: #{e} to #{@entity}"
        @entity.alias e
        @entity.save
      end
    end

    @entity.enriched = true

  end

  def check_options_endpoint(uri)
    response = http_request(:options, uri)
    (response["allow"] || response["Allow"]) if response
  end

  def check_webdav_endpoint(uri)
    http_request :propfind, uri
  end

  def check_api_endpoint(response)
    return true if response.header['Content-Type'] =~ /application/
  false
  end

  def check_forms(response_body)
    return true if response_body =~ /<form/i
  false
  end

end
end
end
