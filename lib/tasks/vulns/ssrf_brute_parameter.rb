require 'webrick'

module Intrigue
module Task
class SsrfBruteParameters < BaseTask

  def self.metadata
    {
      :name => "vuln/ssrf_brute_parameters",
      :pretty_name => "Vulnerability Check - Brute Parameters for SSRF",
      :authors => ["jcran"],
      :identifiers => [{ "cve" =>  false }],
      :description => "Generic SSRF Payload Tester",
      :references => [],
      :type => "vulnerability_check",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [
        {"type" => "Uri", "details" => {"name" => "https://intrigue.io"}}
      ],
      :allowed_options => [
        {:name => "parameter_list", :regex => "alpha_numeric_list", :default => "url,uri,location,host" }
      ],
      :created_types => []
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    uri = _get_entity_name
    parameter_list = _get_option("parameter_list").split(",")

    _log "Starting SSRF Responder server"
    Intrigue::Task::Server::SsrfResponder.start_and_background

    #"http://169.254.169.254/latest/meta-data/",   # AWS Metadata

    parameter_list.each do |parameter|

      # make the request and collect the response
      # https://stackoverflow.com/questions/7012810/url-encoding-ampersand-problem
      payload = "http://localhost:55555?int_id=#{@task_result.id}%26int_param=#{parameter}" 
      generated_test_uri = "#{uri}?#{parameter}=#{payload}"
      response  = http_request :get, generated_test_uri
      _log "Sent: (#{generated_test_uri}), Got: #{response.code}"

    end

  end

end
end
end
