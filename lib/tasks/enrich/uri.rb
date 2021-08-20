module Intrigue
module Task
module Enrich
class Uri < Intrigue::Task::BaseTask

  def self.metadata
    {
      :name => "enrich/uri",
      :pretty_name => "Enrich Uri",
      :authors => ["jcran"],
      :description => "Fills in details for a URI",
      :references => [],
      :type => "enrichment",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [
        {"type" => "Uri", "details" => {"name" => "https://intrigue.io"}}],
      :allowed_options => [
        {:name => "correlate_endpoints", :regex => "boolean", :default => false }
      ],
      :created_types => []
    }
  end

  def run

    uri = _get_entity_name
    begin
      hostname = URI.parse(uri).host
      port = URI.parse(uri).port
      scheme = URI.parse(uri).scheme
    rescue URI::InvalidURIError => e
      _log_error "Error parsing... #{uri}"
      return nil
    end

    _log "Making initial requests, following redirect"
    # Grab the full response
    response = http_request :get, uri
    response2 = http_request :get, uri

    if [response.code, response2.code].all? { |code| code == '0' }
      _log_error "Unable to reach #{uri}, bailing"
      @entity.hidden = true
      @entity.save_changes
      return # no point in doing additional logic
    end

    unless response && response2 && response.body_utf8
      _log_error "Unable to receive a response for #{uri}, bailing"
      return
    end

    # parse out the hostname and parent domains, and create them
    unless hostname.is_ip_address?
      create_dns_entity_from_string parse_domain_name(hostname)

      # seemingly, you would want to enable hostname here, but it
      # can create issues with some pages that will simply repeat
      # whatever their givn hostname is, and thus, we need to find
      # a way to detect that... ala 2f2f2f2f2www.org.com
      #  create_dns_entity_from_string hostname

    end

    ###
    ### grab the page title
    match = response.body_utf8.match(/<title>(.*?)<\/title>/i)
    title = match.captures.first if match

    # Sha256 the body response, in case it's helpful later ont
    response_data_hash = Digest::SHA256.base64digest(response.body_utf8)

    # grab all script_references, normalize to include full uri if needed
    _log "Parsing out Scripts"
    temp_script_links = response.body_utf8.scan(/<script.*?src=["|'](.*?)["|']/).map{ |x| x.first if x }
    # add http/https where appropriate
    temp_script_links = temp_script_links.map{ |x| x.match(/^\/\//) ? "#{scheme}:#{x}" : x }
    # add base_url where appropriate
    script_links = temp_script_links.map{ |x| x.match(/^\//) ? "#{uri}#{x}" : x }

    # Save the Headers
    headers = []
    _log "Saving Headers"
    headers = response.headers.map{|x,y| "#{x}: #{y}"}

    # Use intrigue-ident code to request all of the pages we
    # need to properly fingerprint...  use ident to fingerprint
    _log "Fingerprinting endpoint!"
    ident_result = fingerprint_url(uri)

    # fingerprint our javascript components
    _log "Fingerprinting endpoint's linked scripts"
     script_fingerprint = fingerprint_links(script_links, hostname)
     ident_result["fingerprint"].concat script_fingerprint

    # split out the individual ident components
    ident_fingerprint = ident_result["fingerprint"]
    _log "Got fingerprinted components: #{ident_fingerprint.map{|x| x["product"] }}"

    ident_content = ident_result["content"]
    ident_responses = ident_result["responses"]

    # Log our fingerprint count
    _log "Got #{ident_fingerprint.count} fingerprints!"

    # get the request/response we made so we can keep track of redirects
    _log "Received #{ident_responses.count} responses for fingerprints!"

    # parse through the issues create issues if we have a known tag
    create_issues_from_fingerprint_tags(ident_fingerprint, @entity)

    ##
    ## Process interesting content checks that requested an issue be created
    ## ** Note that this is currently specific to URI's only. **
    ##
    issues_to_be_created = ident_content.concat(
      ident_fingerprint).collect{ |x| x["issues"] }.flatten.compact.uniq
      _log "Issues to be created: #{issues_to_be_created}"
      (issues_to_be_created || []).each do |c|
        _create_linked_issue c, {proof: uri}
    end

    # if we ever match something we know the user won't
    # need to see (aka the fingerprint's :hide parameter is true), go ahead
    # and hide the entity... meaning no recursion and it shouldn't show up in
    # the UI / queries if any of the matches told us to hide the entity, do it.
    # EXAMPLE TEST CASE: http://103.24.203.121:80 (cpanel missing page)
    #
    # ** Currently specific to URIs **
    #
    if ident_fingerprint.detect{|x| x["hide"] == true }
      _log "Entity hidden and unscoped based on fingerprint!"
      @entity.hidden = true
      @entity.save_changes
    end

    # drop them if we are a lookup by ip and just got a reset
    #
    #  ... note that this /could/ be a hide check if it weren't
    #  also used on network services. basically special cased
    #  for this reason alone.
    #
    if "#{URI.parse(@entity.name).host}".is_ip_address? &&
      ident_fingerprint.detect{|x|
        x["product"] == "Connection Reset (attempted HTTP connection)" }
      hide_value = true
      hide_reason = "reset when connecting"
    end

    ###
    ### These should move to ident and set the hidden attribute
    ###
    shared_infra_titles = [
      # "403 - Forbidden: Access is denied.", # http://104.47.66.10:80
      # "404 Not Found",
      "Dmarcian - Protect Your Email and Domain with DMARC",
      "404 Vhost unknown", # http://217.70.185.65:80
      "Amazon.com.au: Shop online for Electronics, Apparel, Toys, Books, DVDs & more", # http://52.119.170.38:80
      "Amazon.co.uk: Low Prices in Electronics, Books, Sports Equipment & more",
      "Amazon.de: Gnstige Preise fr Elektronik & Foto, Filme, Musik, Bcher, Games, Spielzeug & mehr", # http://52.95.115.154:80
      "Cloud Object Storage | Store &amp; Retrieve Data Anywhere | Amazon Simple Storage Service (S3)", # http://52.217.12.131:80
      "Google", # http://172.217.14.165:80
      "Not Found on Accelerator", # http://208.109.192.71:80
      "Not Found Medium", # https://52.1.147.205:443
      "Sign in to Outlook", # http://40.97.160.2:80
      "Sign in to your account", # https://104.47.55.138:443
      "Oracle.com Outage", # http://156.151.59.19:80
      "My Dyn Account" # http://162.88.175.1:80
    ]

    # hide if we get an ip address
    if "#{URI.parse(@entity.name).host}".is_ip_address? &&
          shared_infra_titles.include?(title)
      @entity.hidden = true
      @entity.save_changes
    end

    # we can check the existing response, so send that
    _log "Checking if Forms"
    contains_forms = check_forms(ident_content)

    # we can check the existing response, so send that
    _log "Checking if Authenticated"
    contains_auth = check_auth(ident_content)

    _log "Checking if Authenticated (basic auth)"
    contains_auth_basic = check_auth_by_type(ident_content, "Authentication - HTTP")

    _log "Checking if Authenticated (ntlm auth)"
    contains_auth_ntlm = check_auth_by_type(ident_content, "Authentication - NTLM")

    _log "Checking if Authenticated (forms auth)"
    contains_auth_forms = check_auth_by_type(ident_content, "Authentication - Forms")

    # we can check the existing response, so send that
    _log "Checking if 2FA Identified"
    contains_auth_2fa = check_auth_2fa(ident_content)

    # we'll need to make another request
    _log "Checking OPTIONS"
    verbs_enabled = check_options_endpoint(uri)

    # figure out ciphers if this is an ssl connection
    # only create issues if we're getting a 200
    if response.code == "200"

      # capture cookies
      set_cookie = [ response.headers['set-cookie'] || response.headers["Set-Cookie"] ].flatten.compact
      _log "Got Cookie: #{set_cookie}" if !set_cookie.empty?

      # TODO - cookie scoped to parent domain
      if !set_cookie.empty?
        domain_cookies = set_cookie.map{|x|
          x.split(";").detect{|x| x.match(/Domain=/i) }}.compact.map{|x|x.strip}
        _log "Domain Cookies: #{domain_cookies}"
      end

      if scheme == "https"

        _log "HTTPS endpoint, checking security, grabbing certificate..."

        # grab and parse the certificate
        cert = get_certificate(hostname,port)
        if cert
          alt_names = parse_names_from_cert(cert) || []
          alt_names.each do |an|
            create_dns_entity_from_string an
          end
        else
          alt_names = []
        end

        _log "Got cert's alt names: #{alt_names}"

        if set_cookie

          # temporarily disabled to address false positives - jcran
          # wide scoped cookie
          #if set_cookie.map{|x| x.split(";").find{ |x|
          #          x =~ /Domain=".#{parse_domain_name(uri)};"/i }}
          #  _create_wide_scoped_cookie_issue(uri, set_cookie)
          #end

          # create an issue if not detected
          unless set_cookie.map{|x| x.split(";").find{|x| x =~ /httponly/i }}
            # 4 since we only create an issue if it's an auth endpoint
            _create_missing_cookie_attribute_http_only_issue(uri, set_cookie)
          end

          unless set_cookie.map{|x| x.split(";").detect{|x| x =~ /secure/i }}
            # set a default,4 since we only create an issue if it's an auth endpoint
            _create_missing_cookie_attribute_secure_issue(uri, set_cookie)
          end


        end

        _log "Gathering ciphers since this is an ssl endpoint"
        accepted_connections = _gather_supported_ciphers(hostname,port).select{|x|
          x[:status] == :accepted }

        # Create findings if we have a weak cipher
        if accepted_connections && accepted_connections.detect{ |x| x[:weak] == true }
          create_weak_cipher_issue(uri, accepted_connections)
        end

        # Create findings if we have a deprecated protocol
        if accepted_connections && accepted_connections.detect{ |x|
            ("#{x[:version]}".match(/SSL/) || "#{x[:version]}" == "TLSv1" ) }

          _create_deprecated_protocol_issue(uri, accepted_connections)
        end

      else # http endpoint, just check for httponly

        if set_cookie

          # create an issue if not detected
          if set_cookie.map{|x| x.split(";").detect{|x| x.match(/httponly/i) }}.compact.empty?
            _create_missing_cookie_attribute_http_only_issue(uri, set_cookie)
          end
        end

        alt_names = []

      end
    else
      _log "Did not receive 200, got #{response.code}!"
    end

    ###
    ### get the favicon & hash it (TODO ... add murmurhash)
    ###
    _log "Getting Favicon"
    favicon_response = http_request(:get, "#{uri}/favicon.ico")

    if favicon_response && favicon_response.code == "200"
      favicon_data = Base64.strict_encode64(favicon_response.body_utf8)
      favicon_md5 = Digest::MD5.hexdigest(favicon_response.body_utf8)
      favicon_sha1 = Digest::SHA1.hexdigest(favicon_response.body_utf8)
    end

    # save off the generator string
    generator_match = response.body_utf8.match(/<meta name=\"?generator\"? content=\"?(.*?)\"?\/>/i)
    generator_string = generator_match.captures.first.gsub("\"","") if generator_match

    # resolve until we hit an ip address
    _log "Looking up network and hostname"
    hostname = URI(uri).hostname
    resolved_ip_address = hostname if hostname.is_ip_address?
    tries = 0; max_tries=5
    until "#{resolved_ip_address}".is_ip_address? || (tries > max_tries)
      tries +=1
      ### TODO ... keep track of load balancers etc here.
      resolved_ip_address = "#{resolve_name(hostname)}"
    end

    # look up the details in team cymru's whois, for ASN etc
    ###
    ### TODO ... move to whois!!!!
    ###
    if resolved_ip_address.is_ip_address?
      # if we found an IP from the previous attempt at resolving, create the entity.
      _log 'Creating IPAddress entity.'
      _create_entity 'IpAddress', { name: resolved_ip_address }
      
      resp = cymru_ip_whois_lookup(resolved_ip_address)
      net_geo = resp[:net_country_code]
      net_name = resp[:net_name]

      _log "Geolocating..."
      location_hash = geolocate_ip(resolved_ip_address)
      if location_hash.nil? 
        _log "Unable to retrieve Gelocation."
      else
        _set_entity_detail("geolocation", location_hash)
      end
    end

    # get the hashed dom structure
    dom_sha1 = Digest::SHA1.hexdigest(html_dom_to_string(response.body_utf8))

    # set up the new details
    new_details = {
      "alt_names" => alt_names,
      "auth.any" => contains_auth,
      "auth.basic" => contains_auth_basic,
      "auth.forms" => contains_auth_forms,
      "auth.ntlm" => contains_auth_ntlm,
      "auth.2fa" => contains_auth_2fa,
      "code" => response.code,
      "cookies" => set_cookie,
      "domain_cookies" => domain_cookies,
      "favicon_md5" => favicon_md5,
      "favicon_sha1" => favicon_sha1,
      "ip_address" => resolved_ip_address,
      "net_name" => net_name,
      "net_geo" => net_geo,
      "fingerprint" => ident_fingerprint.uniq,
      "forms" => contains_forms,
      "generator" => generator_string,
      "headers" => headers,
      "redirect_chain" => ident_responses.first[:response_urls] || [],
      "response_data_hash" => response_data_hash,
      "dom_sha1" => dom_sha1,
      "title" => title,
      "verbs" => verbs_enabled,
      "scripts" => script_links,
      "extended_ciphers" => accepted_connections,                  # new ciphers field
      "extended_configuration" => ident_content.uniq,        # new content field
      "extended_full_responses" => ident_responses.uniq,           # includes all the redirects etc
      "extended_favicon_data" => favicon_data,
      "extended_response_body" => response.body_utf8
    }

    # Set the details, and make sure raw response data is a hidden (not searchable) detail
    _get_and_set_entity_details new_details

    ###
    ### Alias Grouping
    ###

    if _get_option("correlate_endpoints")
      # Check for other entities with this same response hash
      _log "Attempting to identify aliases"
        # parse our content with Nokogiri
      our_doc = "#{response.body_utf8}".sanitize_unicode
      Intrigue::Core::Model::Entity.scope_by_project_and_type(
        @entity.project.name,"Uri").paged_each(:rows_per_fetch => 100) do |e|
        next if @entity.id == e.id

        # Do some basic up front checking
        # TODO... make this a filter using JSONb in postgres
        old_title = e.get_detail("title")
        unless "#{title}".strip.sanitize_unicode == "#{old_title}".strip.sanitize_unicode
          _log "Skipping #{e.name}, title doesnt match (#{old_title})"
          next
        end

        # check response code
        unless response.code == e.get_detail("code")
          _log "Skipping #{e.name}, code doesnt match"
          next
        end

        # check fingeprint
        unless ident_fingerprint.uniq.map{ |x|
          "#{x["vendor"]} #{x["product"]} #{x["version"]}"} == e.get_detail("fingerprint").map{ |x|
            "#{x["vendor"]} #{x["product"]} #{x["version"]}" }
          _log "Skipping #{e.name}, fingerprint doesnt match"
          next
        end

        # if we made it this far, parse them & compare them
        # TODO ... is this overkill?
        their_doc = e.details["extended_response_body"]
        diffs = parse_html_diffs(our_doc, their_doc)
        their_doc = nil

        # if they're the same, alias
        if diffs.empty?
          _log "No difference, match found!! Attaching to entity: #{e.name}"
          e.alias_to @entity.alias_group_id
        end

        e = nil
      end
    end

    ###
    ### Do the cloud provider determination
    ###

    # Now that we have our core details, check cloud statusi
    cloud_providers = determine_cloud_status(@entity)
    _set_entity_detail("cloud_providers", cloud_providers.uniq.sort)
    _set_entity_detail("cloud_hosted",  !cloud_providers.empty?)

    ###
    ### Create issues for any vulns that are version-only inference
    ###
    fingerprint_to_inference_issues(ident_fingerprint)

    ###
    ### Kick off vuln checks if enabled for the project
    ###
    all_checks = []
    if @project.vulnerability_checks_enabled
      vuln_checks = run_vuln_checks_from_fingerprint(ident_fingerprint, @entity)
      _set_entity_detail("vuln_checks", vuln_checks)
    end

  end

  def _gather_supported_ciphers(hostname,port)
    scanner = Rex::SSLScan::Scanner.new(hostname, port)
    result = scanner.scan
  result.ciphers.to_a
  end

  def check_options_endpoint(uri)
    response = http_request(:options, uri)
    (response.headers["allow"] || response.headers["Allow"]) if response
  end

  # checks to see if we had an auth config return true
  def check_forms(configuration)
    configuration.each do |c|
      if "#{c["name"]}".match(/^Form Detected$/) && "#{c["value"]}".to_bool
        return true
      end
    end
  false
  end

  # checks to see if we had an auth config return true
  def check_auth(configuration)
    configuration.each do |c|
      if "#{c["name"]}".match(/^Authentication\ \-.*$/) && "#{c["value"]}".to_bool
        return true
      end
    end
  false
  end


  # checks to see if we had an auth config return true
  def check_auth_by_type(configuration, auth_type)
    configuration.each do |c|
      if "#{c["name"]}" == auth_type && "#{c["result"]}".to_bool
        return true
      end
    end
  false
  end

  # checks to see if we had an auth config return true
  def check_auth_2fa(fingerprint)
    fingerprint.each do |fp|
      # check the intersection of these
      if ( (fp["tags"]||[]).map(&:upcase) & ["IAM","SSO","MFA","2FA"] ).any?
        return true
      end
    end
  false
  end


end
end
end
end