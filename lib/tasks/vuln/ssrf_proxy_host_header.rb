module Intrigue
module Task
class SsrfProxyHostHeader < BaseTask

  def self.metadata
    {
      :name => "vuln/ssrf_proxy_host_header",
      :pretty_name => "Vuln Check - Check SSRF in Proxy Host header",
      :authors => ["jcran"],
      :identifiers => [
        { "cve" =>  false },
        { "cwe" =>  "CWE-918" }
      ],
      :description => "Abuses Host header in a reverse proxy" +
                      "setup and checks for SSRF'able content",
      :references => [
        "https://portswigger.net/kb/papers/crackingthelens-whitepaper.pdf"
      ],
      :type => "vuln_check",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [
        {"type" => "Uri", "details" => {"name" => "https://intrigue.io"}}
      ],
      :allowed_options => [
        {:name => "ssrf_target_uri", :regex => "alpha_numeric_list", :default => "http://localhost:55555" },
        {:name => "target_environment", :regex => "alpha_numeric_list", :default => "all" }
      ],
      :created_types => []
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    uri = _get_entity_name
    opt_target_env = _get_option("target_environment")

    payloads = [
      {
        :environment => "local",
        :name => "Localhost",
        :host => "127.0.0.1",
        :path => "/",
        :success_regex => /^.*$/
      },
      #{
      #  :environment => "aws",
      #  :name => "AWS Credential Metadata",
      #  :host => "169.254.169.254",
      #  :path => "/latest/meta-data/",
      #  :success_regex => /Code\"/
      #},
      #{
      #  :environment => "aws",
      #  :name => "AWS Host Metadata",
      #  :host => "169.254.169.254",
      #  :path => "/latest/meta-data/hostname",
      #  :success_regex => /$.*internal$/
      #},
      #{
      #  :environment => "azure",
      #  :name => "Azure Metadata",
      #  :host => "169.254.169.254",
      #  :path => "/metadata/instance?api-version=2017-08-01",
      #  :success_regex => /compute\"/
      #}
    ]

    _log "Starting SSRF Responder server"
    Intrigue::Task::Server::SsrfResponder.start_and_background

    # TODO We should test here for an ignored host header - just send nonsense
    # and see if it behaves the same (returns same content), if so, probably not
    # worth checking
    normal = http_request :get, uri
    #nonsense_response = http_request :get, uri, nil, {"Host" => "-1"}
    #response = http_request :get, uri, nil, {"Host" => "-1"}

    payloads.each do |payload|

      # if we're not checking all, then we should match the desired environment
      if opt_target_env != "all"
        unless opt_target_env.split(",").include? "#{payload[:environment]}"
          _log "Skipping #{payload[:environment]}, target set to #{opt_target_env.split(",")}"
          next
        end
      end

      # make the request and collect the response
      # TODO... handle a trailing slash here
      generated_uri = "#{uri}#{payload[:path]}"

      # call with the host header, and make sure not to follow redirects (we can end
      # up returning our own creds o_0
      response = http_request :get, generated_uri, nil, {"Host" => payload[:host] }, nil, 1

      #_log "Testing payload: #{payload} on #{generated_uri}"

      # check the response for success
      if response &&
          response.body[0..50] != normal.body[0..50] # && # not the same
          #!(response["location"] =~ /127.0.0.1/) && # redirect... usually useless
          #response.code != "301" && # redirect... usually useless
          #response.code != "302" && # redirect... usually useless
          #response.code != "400" && # sometimes it's a generic 400, useless
          #response.code != "403" && # not a 403 (Cloudfront)
          #response.code != "404" # not a 404

          # only if it matches our success cond.
          unless response.body.match(payload[:success_regex])
            _log "Interesting response, but doesn't match our success criteria"
            _log "---"
            _log "#{response.body}"
            _log "---"
            next
          end

          _log "SUCCESS!"

        #_set_entity_detail "host_header_ssrf", {
        #  "host_header" => "#{payload[:host_header]}",
        #  "code" => "#{response.code}",
        #  "body" => "#{response.body}"
        #}

        # save off enough information to investigate
        ssrf_issue = {
          name: "Potential #{payload[:environment]} SSRF",
          type: "vulnerability",
          description: "SSRF on #{uri}",
          severity: 3,
          status: "potential",
          details: {
            uri: "#{generated_uri}",
            host_header: "#{payload[:host]}",
            code: "#{response.code}",
            body: "#{response.body.sanitize_unicode}",
            normal_code: "#{normal.code}",
            normal_body: "#{normal.body.sanitize_unicode}"
          }
        }

          if response.code =~ /^3/
            ssrf_issue[:details][:redirect_location] = response["location"]
          end

        _create_issue ssrf_issue

      else

        _log "FAIL!"
        if response
          _log "Code: #{response.code}"
          _log "Response same as normal: #{response.body[0..199] == normal.body[0..199]}"
          _log "Response: #{response.body[0..79]}"
        else
          _log "No response!"
        end

      end

    end # end payloads

  end

end
end
end
