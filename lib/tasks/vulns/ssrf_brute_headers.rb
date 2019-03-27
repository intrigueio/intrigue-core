module Intrigue
module Task
class SsrfBruteHeaders < BaseTask

  def self.metadata
    {
      :name => "vuln/ssrf_brute_headers",
      :pretty_name => "Vuln - Brute Headers for SSRF",
      :authors => ["jcran"],
      :identifiers => [
        { "cve" =>  false },
        { "cwe" =>  "CWE-918" }
      ],
      :description => "Generic SSRF Payload Tester",
      :references => [],
      :type => "vuln_check",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [
        {"type" => "Uri", "details" => {"name" => "https://intrigue.io"}}
      ],
      :allowed_options => [
        {:name => "ssrf_target_uri", :regex => "alpha_numeric_list", :default => "http://localhost:55555" },
        {:name => "header_list", :regex => "alpha_numeric_list", :default => "referer,url,uri,location,host" }
      ],
      :created_types => []
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    uri = _get_entity_name
    ssrf_target_uri = _get_option("ssrf_target_uri")
    header_list = _get_option("header_list").split(",")

    _log "Starting SSRF Responder server"
    Intrigue::Task::Server::SsrfResponder.start_and_background

    header_list.each do |header|

      # make the request and collect the response
      # https://stackoverflow.com/questions/7012810/url-encoding-ampersand-problem
      payload = "#{ssrf_target_uri}?int_id=#{@task_result.id}%26int_header=#{header}"
      generated_test_uri = "#{payload}"
      response  = http_request :get, uri, nil, {header => generated_test_uri}
      _log "Sent: (#{generated_test_uri}), Got: #{response.code} for header #{header}"


    end

    # Future work... actually exfil data (enrichment?)
    #"http://169.254.169.254/latest/meta-data/",   # AWS Metadata

  end

end
end
end
