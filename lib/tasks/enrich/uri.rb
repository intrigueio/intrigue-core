module Intrigue
module Task
module Enrich
class Uri < Intrigue::Task::BaseTask

  include Intrigue::Ident
  #include Intrigue::Vulndb

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
      :allowed_options => [],
      :created_types => [],
      :queue => "task_browser"
    }
  end

  def run
    
    uri = _get_entity_name
    begin
      hostname = URI.parse(uri).host
      port = URI.parse(uri).port
    rescue URI::InvalidURIError => e
      _log_error "Error parsing... #{uri}"
      return nil
    end

    _log "Making requests"
    # Grab the full response
    response = http_request :get, uri
    response2 = http_request :get, uri

    unless response && response2 && response.body
      _log_error "Unable to receive a response for #{uri}, bailing"
      return
    end

    response_data_hash = Digest::SHA256.base64digest(response.body)

    # we can check the existing response, so send that
    api_enabled = check_api_endpoint(response)

    # we can check the existing response, so send that
    contains_forms = check_forms(response.body)

    # we'll need to make another request
    verbs_enabled = check_options_endpoint(uri)

    # grab all script_references
    script_links = response.body.scan(/<script.*?src=["|'](.*?)["|']/).map{|x| x.first if x }

    # save the Headers
    headers = []
    response.each_header{|x| headers << "#{x}: #{response[x]}" }

    ### 
    ### Fingerprint Javascript
    ###
    begin
      _log "Creating browser session"
      session = create_browser_session
      
      # note that we might not have a session if it's diabled globally 
      if session 
        # Run the version checking scripts
        _log "Grabbing Javascript libraries"
        js_libraries = gather_javascript_libraries(session, uri)

        # screenshot
        _log "Capturing screenshot"
        encoded_screenshot = capture_screenshot(session, uri)
      end

    ensure
      # kill the session / cleanup - if we never had a session, this'll 
      # just complete gracefully
      _log "Destroying browser session"
      destroy_browser_session(session)
    end

    # Grab the global option since we'll need to pass it to ident
    browser_enabled = Intrigue::Config::GlobalConfig.config["enable_browser"]

    _log "Attempting to fingerprint!"
    # Use intrigue-ident code to request all of the pages we
    # need to properly fingerprint
    ident_matches = generate_http_requests_and_check(uri,browser_enabled) || {}

    ident_fingerprints = ident_matches["fingerprint"] || []
    ident_content_checks = ident_matches["content"] || []

    # get the requests we made so we can save off all details
    ident_responses = ident_matches["responses"]

    if ident_fingerprints.count > 0
      # Make sure the key is set before querying intrigue api
      vulndb_api_key = _get_task_config "intrigue_vulndb_api_key"
      use_api = vulndb_api_key && vulndb_api_key.length > 0
      ident_fingerprints = ident_fingerprints.map do |fp|
        
        #_log "Working on fingerprint: #{fp}"

        vulns = []
        if fp["inference"]
          cpe = Intrigue::Vulndb::Cpe.new(fp["cpe"])
          if use_api # get vulns via intrigue API
            _log "Matching vulns for #{fp["cpe"]} via Intrigue API"
            vulns = cpe.query_intrigue_vulndb_api(vulndb_api_key)
          else 
            vulns = cpe.query_local_nvd_json
          end
        else 
          _log "Skipping inference on #{fp["cpe"]}"
        end

        fp.merge!({"vulns" => vulns })
      end
    end

    # process interesting content checks that requested an issue be created
    issues_to_be_created = ident_content_checks.select {|c| c["issue"] }
    _log "Issues to be created: #{issues_to_be_created}"
    if issues_to_be_created.count > 0
      issues_to_be_created.each do |c|
        create_content_issue(uri, c)
      end
    end

    # if we ever match something we know the user won't
    # need to see (aka the fingerprint's :hide parameter is true), go ahead
    # and hide the entity... meaning no recursion and it shouldn't show up in
    # the UI / queries if any of the matches told us to hide the entity, do it.
    # EXAMPLE TEST CASE: http://103.24.203.121:80 (cpanel missing page)
    if ident_fingerprints.detect{|x| x["hide"] == true }
      @entity.hidden = true
      @entity.save
    end

    # in some cases, we should go further
    #extended_fingerprints = []
    #if ident_fingerprints.detect{|x| x["product"] == "Wordpress" }
    #  wordpress_fingerprint = {"wordpress" => `nmap -sV --script http-wordpress-enum #{uri}`}
    #end
    #extended_fingerprints << wordpress_fingerprint

    # figure out ciphers if this is an ssl connection
    # only create issues if we're getting a 200
    if response.code == "200"

      # capture cookies
      set_cookie = response.header['set-cookie']
      _log "Got Cookie: #{set_cookie}" if set_cookie
      # TODO - cookie scoped to parent domain
      _log "Domain Cookie: #{set_cookie.split(";").detect{|x| x =~ /Domain:/i }}" if set_cookie

      if uri =~ /^https/
        
        _log "HTTPS endpoint, checking security, grabbing certificate..."

        # grab and parse the certificate
        alt_names = connect_ssl_socket_get_cert_names(hostname,port) || []
  
        if set_cookie 
          _log "Secure Cookie: #{set_cookie.split(";").detect{|x| x =~ /secure/i }}"
          _log "Http_only Cookie: #{set_cookie.split(";").detect{|x| x =~ /httponly/i }}"

          # create an issue if not detected
          if !(set_cookie.split(";").detect{|x| x =~ /httponly/i } && 
                set_cookie.split(";").detect{|x| x =~ /secure/i })
            create_insecure_cookie_issue(uri, set_cookie)
          end 

        end

        _log "Gathering ciphers since this is an ssl endpoint"
        accepted_connections = _gather_supported_connections(hostname,port).select{|x| 
          x[:status] == :accepted } 

        # Create findings if we have a weak cipher 
        if accepted_connections && accepted_connections.detect{ |x| x[:weak] == true }
          create_weak_cipher_issue(uri, accepted_connections)
        end

        # Create findings if we have a deprecated protocol
        if accepted_connections && accepted_connections.detect{ |x| 
            (x[:version] =~ /SSL/ || x[:version] == "TLSv1") }     
          create_deprecated_protocol_issue(uri, accepted_connections)
        end

      else # http endpoint 
                
        if set_cookie 
          _log "Http_only Cookie: #{set_cookie.split(";").detect{|x| x =~ /httponly/i }}"

          # create an issue if not detected
          if !set_cookie.split(";").detect{|x| x =~ /httponly/i }
            create_insecure_cookie_issue(uri, set_cookie)
          end 
        end

        alt_names = []

      end

    end

    ###
    ### Fingerprint the app server
    ###
    app_stack = []
    _log "Inferring app stack from fingerprints!"
    ident_app_stack = ident_fingerprints.map do |x|
      version_string = "#{x["vendor"]} #{x["product"]}"
      version_string += " #{x["version"]}" if x["version"]
    version_string
    end
    app_stack.concat(ident_app_stack)
    _log "Setting app stack to #{app_stack.uniq}"

    ###
    ### Product matching
    ###
    products = []
    # match products based on gathered server software
    products << product_match_http_server_banner(response.header['server']).first
    # match products based on cookies
    products << product_match_http_cookies(response.header['set-cookie'])

    ###
    ### grab the page attributes
    match = response.body.match(/<title>(.*?)<\/title>/i)
    title = match.captures.first if match

    # save off the generator string
    generator_match = response.body.match(/<meta name=\"?generator\"? content=\"?(.*?)\"?\/>/i)
    generator_string = generator_match.captures.first.gsub("\"","") if generator_match

    $db.transaction do
      new_details = @entity.details.merge({
        "alt_names" => alt_names,
        "api_endpoint" => api_enabled,
        "code" => response.code,
        "title" => title,
        "generator" => generator_string,
        "verbs" => verbs_enabled,
        "scripts" => script_links,
        "headers" => headers,
        "cookies" => response.header['set-cookie'],
        "forms" => contains_forms,
        "response_data_hash" => response_data_hash,
        "hidden_response_data" => response.body,
        "hidden_screenshot_contents" => encoded_screenshot,
        "javascript" => js_libraries,
        "products" => products.compact,
        "fingerprint" => ident_fingerprints.uniq,
        "content" => ident_content_checks.uniq,
        "ciphers" => accepted_connections
      })

      # Set the details, and make sure raw response data is a hidden (not searchable) detail
      @entity.set_details new_details
    end

    # Check for other entities with this same response hash
    #if response_data_hash
    #  Intrigue::Model::Entity.scope_by_project_and_type_and_detail_value(@entity.project.name,"Uri","response_data_hash", response_data_hash).each do |e|
    #    _log "Checking for Uri with detail: 'response_data_hash' == #{response_data_hash}"
    #    next if @entity.id == e.id
    #
    #    _log "Attaching entity: #{e} to #{@entity}"
    #    @entity.alias e
    #    @entity.save
    #  end
    #end

  end

  def _gather_supported_connections(hostname,port)
    require 'rex/sslscan'
    scanner = Rex::SSLScan::Scanner.new(hostname, port)
    result = scanner.scan
  result.ciphers.to_a
  end


  def check_options_endpoint(uri)
    response = http_request(:options, uri)
    (response["allow"] || response["Allow"]) if response
  end

  def check_api_endpoint(response)
    return true if response.header['Content-Type'] =~ /application/
  false
  end

  def check_forms(response_body)
    return true if response_body =~ /<form/i
  false
  end

  def create_content_issue(uri, check)
    _create_issue({
      name: "Content issue: #{check["name"]} on #{uri}",
      type: "#{check["name"].downcase.gsub(" ","_")}",
      severity: 4, # todo... 
      status: "confirmed",
      description: "This server had a content issue: #{check["name"]}.",
      references: [],
      details: { 
        uri: uri,
        check: check 
      }
    })
  end

  def create_insecure_cookie_issue(uri, cookie)
    _create_issue({
      name: "Insecure cookie detected on #{uri}",
      type: "insecure_cookie_detected",
      severity: 5,
      status: "confirmed",
      description: "This server is configured without secure or httpOnly cookie flags",
      references: [],
      details: { 
        uri: uri,
        cookie: cookie 
      }
    })
  end

  def create_weak_cipher_issue(uri, accepted_connections)
    _create_issue({
      name: "Weak ciphers enabled on #{uri}",
      type: "weak_cipher_suite_detected",
      severity: 5,
      status: "confirmed",
      description: "This server is configured to allow a known-weak cipher suite",
      #recommendation: "Disable the weak ciphers.",
      references: [
        "https://thycotic.com/company/blog/2014/05/16/ssl-beyond-the-basics-part-2-ciphers/"
      ],
      details: { 
        uri: uri,
        allowed: accepted_connections 
      }
    })
  end

  def create_deprecated_protocol_issue(uri, accepted_connections)
    _create_issue({
      name: "Deprecated protocol enabled on #{uri}",
      type: "deprecated_protocol_detected",
      severity: 5,
      status: "confirmed",
      description: "This server is configured to allow a deprecated ssl / tls protocol",
      #recommendation: "Disable the protocol, ensure support for the latest version.",
      references: [
        "https://tools.ietf.org/id/draft-moriarty-tls-oldversions-diediedie-00.html"
      ],
      details: { 
        uri: uri,
        allowed: accepted_connections 
      }
    })
  end

end
end
end
end