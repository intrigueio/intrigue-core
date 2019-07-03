module Intrigue
module Task
class SearchCertSpotter < BaseTask
  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "search_certspotter",
      :pretty_name => "Search CertSpotter",
      :authors => ["jcran"],
      :description => "This task hits SSLMate's CertSpotter API and creates new DnsRecord / Certificate entities.",
      :references => ["https://www.virustotal.com/en/documentation/"],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["Domain","DnsRecord"],
      :example_entities => [ {"type" => "DnsRecord", "details" => {"name" => "intrigue.io"}} ],
      :allowed_options => [
        {:name => "extract_patterns", :regex => "alpha_numeric_list", :default => "default" },
      ],
      :created_types => ["DnsRecord", "SslCertificate"]
    }
  end

  def run
    super

    search_domain = _get_entity_name
    api_key = _get_task_config("certspotter_api_key")

    # default to our name for the extract pattern
    if _get_option("extract_patterns") != "default"
      extract_patterns = _get_option("extract_patterns")
    else
      extract_patterns = [search_domain]
    end

    search_url = "https://api.certspotter.com/v1/issuances?domain=#{search_domain}&include_subdomains=true&expand=dns_names" + 
    "&expand=issuer&expand=not_before&expand=not_after&expand=cert&expand=tbs_sha256&expand=pubkey_sha256&expand=id"

    begin

      response = http_request :get, search_url, nil, {"Authorization" => "Bearer #{api_key}"}
      json = JSON.parse(response.body)

      # a little wicked but we want to only select those that match our pattern(s)
      records = json.map do |x|
        next unless x && x.kind_of?(Hash)

        # unbase64 the jason
        cert_raw = OpenSSL::ASN1.decode(Base64.decode64(x["cert"]["data"]))
        cert = OpenSSL::X509::Certificate.new cert_raw

        # Create the SSLCertificate
        _create_entity "SslCertificate", {
          "cert_type" => x["type"],
          "name" => "#{cert.subject.to_s.gsub("/CN=","")} (#{cert.serial.to_s})", 
          "issuer" => cert.issuer.to_s,
          "not_before" => cert.not_before.to_s,
          "not_after" => cert.not_after.to_s,
          "serial" => cert.serial.to_s,
          "subject" => cert.subject.to_s,
          "hidden_text" => cert.to_text
        }

        x["dns_names"].map do |d|
          next unless x["dns_names"]
          d if extract_patterns.select {|p| d =~ /#{p}/}.count > 0 
        end
      end
      
      records.flatten.compact.uniq.each do |domain|

        # remove any whitespace, and skip if it's a wildcard
        if domain == "*"
          _log "Skipping wildcard: #{domain}.#{search_domain}"
          next
        end
      
        # Remove any leading wildcards
        domain = domain[2..-1] if domain[0..1] == "*."
          
        # woot, made it
        _create_entity("DnsRecord", "name"=> "#{domain}" )
      end

    rescue JSON::ParserError => e 
      _log_error "Unable to parse json!"
    end

  end

end
end
end
