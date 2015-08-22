module Intrigue
class UriGatherHeadersTask  < BaseTask

  include Intrigue::Task::Web

  def metadata
    {
      :name => "uri_gather_headers",
      :pretty_name => "URI Gather Headers",
      :authors => ["jcran"],
      :description =>   "This task checks for HTTP headers on a web application",
      :references => [],
      :allowed_types => ["Uri"],
      :example_entities => [{"type" => "Uri", "attributes" => {"name" => "http://www.intrigue.io"}}],
      :allowed_options => [], # TODO
      :created_types => ["UriHeader"]
    }
  end

  def run
    super

    uri = _get_entity_attribute "name"

    response = http_get(uri)

    if response
      response.each_header do |name,value|
        _create_entity("UriHeader", {
          "name" => "#{name}",
          "content" => "#{value}" })
      end
    end
  end

  end
  end
