module Intrigue
class UriCheckSecurityHeaders  < BaseTask

  include Intrigue::Task::Web

  def metadata
    {
      :name => "uri_check_security_headers",
      :pretty_name => "URI Check Security Headers",
      :authors => ["jcran"],
      :description =>   "This task checks for typical HTTP security headers on a web application",
      :references => [],
      :allowed_types => ["Uri"],
      :example_entities => [{"type" => "Uri", "attributes" => {"name" => "http://www.intrigue.io"}}],
      :allowed_options => [],
      :created_types => ["Info"]
    }
  end

  def run
    super

    uri = _get_entity_attribute "name"

    response = http_get(uri)

    security_headers = [ "strict-transport-security", "x-frame-options",
      "x-xss-protection", "x-content-type-options", "content-security-policy",
      "content-security-policy-report-only"]

    if response
      found_security_headers = []
      response.each_header do |name,value|
        @task_result.log "Checking #{name}"
        if security_headers.include? name
          @task_result.log_good "Got header #{name}"
          found_security_headers << {:name => name, :value => value}
        end # end if
      end # end each_header

      # If we have identified any headers...
      if found_security_headers.count > 0
        _create_entity("Info", {
          "name" => "#{uri} provides HTTP security headers",
          "uri" => "#{uri}",
          "security_header_check" => true,
          "security_headers" => found_security_headers,
          #"headers" => response.each_header.map{|name,value| {:name => name, :value => value}  }
          })
      end

    end # response
  end #end run

end
end
