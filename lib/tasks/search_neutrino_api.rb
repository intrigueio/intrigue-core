require 'neutrino_api'
module Intrigue
module Task
class SearchNeutrinoAPI < BaseTask

  def self.metadata
    {
      :name => "search_neutrino_api",
      :pretty_name => "Search NeutrinoAPI",
      :authors => ["Anas Ben Salah"],
      :description => "This task hits NeutrinoAPI.",
      :references => [],
      :type => "discovery",
      :allowed_types => ["IpAddress"],
      :example_entities => [
        {"type" => "IpAddress", "details" => {"name" => "1.1.1.1"}}
      ],
      :allowed_options => [
        {:name => "description", :regex=> "boolean", :default => true },
        {:name => "fix_typos", :regex=> "boolean", :default => false }
      ],
      :created_types => ["IpAddress"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    entity_name = _get_entity_name
    entity_type = _get_entity_type_string

    # This option enable the full prob IP api and consume API request notice that for regular use you have 10k of IP prob and 100k of IP blocklist request
    opt_description = _get_option("description")

    #Automatically attempt to fix typos in the address
    fix_typos = _get_option("fix_typos")

    user_id =_get_task_config("neutrinoapi_user_id")
    master_key =_get_task_config("neutrinoapi_master_key")

    unless master_key or user_id
        _log_error "unable to proceed, no API key for Dehashed provided"
        return
    end

    description = nil

    client = NeutrinoApi::NeutrinoApiClient.new(
      user_id: user_id,
      api_key: master_key
    )

    securityAndNetworking_controller = client.security_and_networking

    if opt_description == true
      description = get_full_ip_info securityAndNetworking_controller, entity_name
      search_ip_blocklist securityAndNetworking_controller, entity_name, description
    else
      description = "Not selected as an option"
      search_ip_blocklist securityAndNetworking_controller, entity_name, description
    end

  end


  # Perform a live (realtime) scan against the given IP using various network level checks
  def get_full_ip_info securityAndNetworking_controller, entity_name

    result = securityAndNetworking_controller.ip_probe(entity_name)

    # Full country name
    # @return [String]
    country = result.country

    # The detected provider type, possible values are: <ul> <li>isp - IP belongs
    # to an internet service provider. This includes both mobile, home and
    # business internet providers</li> <li>hosting - IP belongs to a hosting
    # company. This includes website hosting, cloud computing platforms and
    # colocation facilities</li> <li>vpn - IP belongs to a VPN provider</li>
    # <li>proxy - IP belongs to a proxy service. This includes HTTP/SOCKS
    # proxies and browser based proxies</li> <li>university - IP belongs to a
    # university/college/campus</li> <li>government - IP belongs to a government
    # department. This includes military facilities</li> <li>commercial - IP
    # belongs to a commercial entity such as a corporate headquarters or company
    # office</li> <li>unknown - could not identify the provider type</li> </ul>
    # @return [String]
    provider_type = result.provider_type

    # The IPs full hostname (PTR)
    # @return [String]
    hostname = result.hostname

    # The domain name of the provider
    # @return [String]
    provider_domain = result.provider_domain

    # Full city name (if detectable)
    # @return [String]
    provider_website = result.provider_website

    # The website URL for the provider
    # @return [String]
    ip = result.ip

    # Full region name (if detectable)
    # @return [String]
    region = result.region

    # A description of the provider (usually extracted from the providers website)
    # @return [String]
    provider_description = result.provider_description

    # True if this IP belongs to a hosting company, true even if the provider type is VPN/proxy
    # @return [Boolean]
    is_hosting = (result.is_hosting).to_s

    # True if this IP belongs to an internet service provider, true even if the provider type is VPN/proxy
    # @return [Boolean]
    is_isp = (result.is_isp).to_s

    # True if this IP ia a VPN
    # @return [Boolean]
    is_vpn = (result.is_vpn).to_s

    # True if this IP ia a proxy
    # @return [Boolean]
    is_proxy = (result.is_proxy).to_s

    # The autonomous system (AS) number
    # @return [String]
    asn = result.asn

    # The autonomous system (AS) CIDR range
    # @return [String]
    as_cidr = result.as_cidr

    # Array of all the domains associated with the autonomous system (AS)
    # @return [List of String]
    as_domains = result.as_domains

    # The autonomous system (AS) description / company name
    # @return [String]
    as_description = result.as_description

    # The age of the autonomous system (AS) in number of years since registration
    # @return [Integer]
    as_age = result.as_age

    # The IPs host domain
    # @return [String]
    host_domain = result.host_domain

    # The domain of the VPN provider (may be empty if the VPN domain is not detectable)
    # @return [String]
    vpn_domain = result.vpn_domain


    if as_description
      _create_entity("Organization", {"name" => as_description})
    end

    if host_domain
      _create_entity("Domain", {"name" => host_domain})
    end

    if as_domains
      as_domains.each do |e|
        _create_entity("Domain", {"name" => e })
      end
    end

    if provider_domain
      _create_entity("Domain", {"name" => provider_domain})
    end

    if hostname
      _create_entity("Domain", {"name" => hostname})
    end

    full_description = "country: #{country}, provider_type: #{provider_type}, hostname: #{hostname}, provider_domain: #{provider_domain}, " +
    "provider_website: #{provider_website}, region: #{region}, provider_description: #{provider_description}, " +
    "this compnay is a hosting company or VPN/proxy: #{is_hosting}, This IP belongs to an internet service provider: #{is_isp}," +
    "This IP is VPN: #{is_vpn}, This IP ia a proxy: #{is_proxy}, ASN: #{asn}, as_cidr: #{as_cidr}" +
    "Associated domains to the AS : #{as_domains}, company name: #{as_description}, " +
    "age: #{as_age} year, host_domain: #{host_domain}, vpn_domain: #{vpn_domain}"

    return full_description

  end

  #IP Blocklist will detect potentially malicious or dangerous IP addresses, anonymous proxies, Tor, botnets, spammers and more.
  def search_ip_blocklist securityAndNetworking_controller, entity_name, description

    result_bl = securityAndNetworking_controller.ip_blocklist(entity_name)

    # The IP address
    # @return [String]
    ip = result_bl.ip

    # IP is hosting a malicious bot or is part of a botnet. Includes brute-force crackers
    # @return [Boolean]
    is_bot = (result_bl.is_bot).to_s

    # IP is hosting an exploit finding bot or is running exploit scanning software
    # @return [Boolean]
    is_exploit_bot = (result_bl.is_exploit_bot).to_s

    # IP is involved in distributing or is running malware
    # @return [Boolean]
    is_malware = (result_bl.is_malware).to_s

    # IP is running a hostile web spider / web crawler
    # @return [Boolean]
    is_spider = (result_bl.is_spider).to_s

    # IP has been flagged as an attack source on DShield (dshield.org)
    # @return [Boolean]
    is_dshield = (result_bl.is_dshield).to_s

    # The number of blocklists the IP is listed on
    # @return [Integer]
    list_count = (result_bl.list_count).to_s

    # IP has been detected as an anonymous web proxy or anonymous HTTP proxy
    # @return [Boolean]
    list_count = (result_bl.list_count).to_s

    # IP is part of a hijacked netblock or a netblock controlled by a criminal organization
    # @return [Boolean]
    is_hijacked = (result_bl.is_hijacked).to_s

    # IP is a Tor node or running a Tor related service
    # @return [Boolean]
    is_tor = (result_bl.is_tor).to_s

    # IP is involved in distributing or is running spyware
    # @return [Boolean]
    is_spyware = (result_bl.is_spyware).to_s

    # IP address is hosting a spam bot, comment spamming or any other spamming
    # @return [Boolean]
    is_spam_bot = (result_bl.is_spam_bot).to_s

    # Is this IP on a blocklist
    # @return [Boolean]
    is_listed =  (result_bl.is_listed).to_s

    # IP belongs to a VPN provider. This field is only kept for backward compatibility, for VPN detection
    # @return [Boolean]
    is_vpn = (result_bl.is_vpn).to_s

    # The last time this IP was seen on a blocklist (in Unix time or 0 if not listed recently)
    # @return [Integer]
    last_seen = (result_bl.last_seen).to_s

    # An array of strings indicating which blocklists this IP is listed on (empty if not listed)
    # @return [List of String]
    blocklists = result_bl.blocklists

    # An array of objects containing details on which sensors were used to detect this IP
    # @return [List of String]
    sensors = result_bl.sensors
    #json = JSON.parse(sensors)
    #puts json


    if is_listed == 'true' or is_bot  == 'true'  or is_exploit_bot == 'true'  or is_malware == 'true'  or is_spider == 'true'  or is_hijacked == 'true'  or is_tor == 'true'  or is_spyware == 'true'  or is_spam_bot == 'true'
      _create_linked_issue("suspicious_ip", {
        status: "confirmed",
        description: "IP is hosting a malicious bot or is part of a botnet: #{is_bot}, " +
        "IP is hosting an exploit finding bot or is running exploit scanning software : #{is_exploit_bot}, " +
        "IP is involved in distributing or is running malware: #{is_malware}, IP is running a hostile web spider / web crawler: #{is_spider} " +
        "IP has been flagged as an attack source on DShield (dshield.org): #{is_dshield}, " +
        "IP is part of a hijacked netblock or a netblock controlled by a criminal: #{is_hijacked}, " +
        "IP is a Tor node or running a Tor related service: #{is_tor}, IP is involved in distributing or is running spyware: #{is_spyware}, " +
        "IP address is hosting a spam bot: #{is_spam_bot}, this IP on a blocklist: #{is_listed}, " +
        "The number of blocklists the IP is listed on: #{list_count}, The last time this IP was seen on a blocklist: #{last_seen} , " +
        "this IP is listed on: #{blocklists}, sensors were used to detect this IP: #{sensors}",
        neutrinoapi_details: description,
        proof: "This IP was founded flaged ",
        source: "NeutrinoAPI"
      })
      # Also store it on the entity
      blocked_list = @entity.get_detail("detected_malicious") || []
      @entity.set_detail("detected_malicious", blocked_list.concat([{source: source}]))
    end
  end

  #def verify_email securityAndNetworking_controller, entity_name, fix_typos
  #  result_ev = securityAndNetworking_controller.email_verify(entity_name, fix_typos)
  #end


end
end
end
