module Intrigue
class CheckApiEndpoint < BaseTask
  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "check_api_endpoint",
      :pretty_name => "Check API Endpoint",
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

    response = http_get uri

    unless response
      _log_error "Unable to receive a response for #{uri}, bailing"
      return
    end

    _log "Server response:"
    response.each_header {|h,v| _log " - #{h}: #{v}" }

    if response.header['Content-Type'] =~ /application/
      _log_good "API Endpoint found!"
      @entity.lock!
      @entity.update(:details => @entity.details.merge("api" => true))
    end

  end

end
end
