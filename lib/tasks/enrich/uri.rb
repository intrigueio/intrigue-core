module Intrigue
module Task
module Enrich
class Uri < Intrigue::Task::BaseTask

  include Intrigue::Ident

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
      :example_entities => [{"type" => "Uri", "details" => {"name" => "https://intrigue.io"}}],
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
    response2 = http_request :get,uri

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

    begin
      _log "Creating browser session"
      session = create_browser_session

      # Run the version checking scripts
      _log "Grabbing Javascript libraries"
      js_libraries = gather_javascript_libraries(session, uri)

      # screenshot
      _log "Capturing screenshot"
      encoded_screenshot = capture_screenshot(session, uri)
    ensure
      # kill the session / cleanup
      _log "Destroying browser session"
      destroy_browser_session(session)
    end

    ###
    ### Fingerprint the server
    ###
    server_stack = []  # Use various techniques to build out the "stack"
    server_stack << _check_server_header(response, response2)
    uniq_server_stack = server_stack.select{ |x| x != nil }.uniq
    _log "Setting server stack to #{uniq_server_stack}"

    ###
    ### Fingerprint the app server
    ###
    app_stack = []
    app_stack.concat _check_uri(uri)
    app_stack.concat _check_cookies(response)
    app_stack.concat _check_generator(response)
    app_stack.concat _check_x_headers(response)

    _log "Attempting to fingerprint!"
    # Use intrigue-ident code to request all of the pages we
    # need to properly fingerprint
    ident_matches = generate_http_requests_and_check(uri) || {}

    ident_fingerprints = ident_matches["fingerprint"] || []
    ident_content_checks = ident_matches["content"] || []

    # get the requests we made so we can save off all details
    ident_responses = ident_matches["responses"]

    if ident_fingerprints
      # Make sure the key is set before querying intrigue api
      vulndb_api_key = _get_task_config "intrigue_vulndb_api_key"
      if vulndb_api_key
        # get vulns via intrigue API
        _log "Matching vulns via Intrigue API"
        ident_fingerprints = ident_fingerprints.map do |m|
          m.merge!({"vulns" => Intrigue::Vulndb::Cpe.new(m["cpe"]).query_intrigue_vulndb_api(vulndb_api_key) })
        end
      else
        # TODO additional checks here?  smaller boxes will have trouble with all the json
        _log "No api_key for vuln match, falling back to local resolution"
        ident_fingerprints = ident_fingerprints.map do |m|
          m.merge!({"vulns" => Intrigue::Vulndb::Cpe.new(m["cpe"]).query_intrigue_vulndb_api })
        end
      end
    end

    # if we ever match something we know the user won't
    # need to see (aka the fingerprint's :hide parameter is true), go ahead
    # and hide the entity... meaning no recursion and it shouldn't show up in
    # the UI / queries if any of the matches told us to hide the entity, do it.
    # EXAMPLE TEST CASE: http://103.24.203.121:80 (cpanel missing page)
    #if ident_fingerprints.detect{|x| x["hide"] == true }
    #  _set_entity_detail "hidden_for"
    #  @entity.hidden = true
    #  @entity.save
    # end

    # in some cases, we should go further
    #extended_fingerprints = []
    #if ident_fingerprints.detect{|x| x["product"] == "Wordpress" }
    #  wordpress_fingerprint = {"wordpress" => `nmap -sV --script http-wordpress-enum #{uri}`}
    #end
    #extended_fingerprints << wordpress_fingerprint

    _log "Gathering ciphers since this is an ssl endpoint"
    accepted_ciphers = _gather_ciphers(hostname,port).select{|x| x[:status] == :accepted} if uri =~ /^https/

    # Create findings if we have a weak cipher
    if accepted_ciphers && accepted_ciphers.detect{|x| x[:weak] == true }
      create_weak_cipher_issue(accepted_ciphers)
    end

    # and then just stick the name and the version in our fingerprint
    _log "Inferring app stack from fingerprints!"
    ident_app_stack = ident_fingerprints.map do |x|
      version_string = "#{x["vendor"]} #{x["product"]}"
      version_string += " #{x["version"]}" if x["version"]
    version_string
    end
    app_stack.concat(ident_app_stack)
    _log "Setting app stack to #{app_stack.uniq}"

    ###
    ### Legacy Fingerprinting (raw regex'ing)
    ###
    include_stack = []
    include_stack.concat _check_page_contents_legacy(response)
    uniq_include_stack = include_stack.select{ |x| x != nil }.uniq
    _log "Setting include stack to #{uniq_include_stack}"

    ###
    ### Product matching
    ###
    # match products based on gathered server software
    products = uniq_server_stack.map{|x| product_match_http_server_banner(x).first}
    # match products based on cookies
    products.concat product_match_http_cookies(_gather_cookies(response))

    ###
    ### grab the page attributes
    match = response.body.match(/<title>(.*?)<\/title>/i)
    title = match.captures.first if match

    match = response.body.match(/<meta name="generator" content=(.*?)>/i)
    generator = match.captures.first.gsub("\"","") if match

    $db.transaction do
      new_details = @entity.details.merge({
        "api_endpoint" => api_enabled,
        "code" => response.code,
        "title" => title,
        "generator" => generator,
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
        "include_fingerprint" => uniq_include_stack,
        "app_fingerprint" =>  app_stack.uniq,
        "server_fingerprint" => uniq_server_stack,
        "fingerprint" => ident_fingerprints.uniq,
        "content" => ident_content_checks.uniq,
        "ciphers" => accepted_ciphers
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

  def _gather_ciphers(hostname,port)
    require 'rex/sslscan'
    scanner = Rex::SSLScan::Scanner.new(hostname, port)
    result = scanner.scan
  result.ciphers
  end


  def _check_page_contents_legacy(response)

    ###
    ### Security Seals
    ###
    # http://baymard.com/blog/site-seal-trust
    # https://vagosec.org/2014/11/clubbing-seals/
    #
    http_body_checks = [
      { :regex => /sealserver.trustwave.com\/seal.js/, :fingerprint_name => "Trustwave Security Seal"},
      { :regex => /Norton Secured, Powered by Symantec/, :fingerprint_name => "Norton Security Seal"},
      { :regex => /PathDefender/, :fingerprint_name => "McAfee Pathdefender Security Seal"},

      ### Marketing / Tracking
      {:regex => /urchin.js/, :fingerprint_name => "Google Analytics"},
      {:regex => /GoogleAnalyticsObject/, :fingerprint_name => "Google Analytics"},
      {:regex => /MonsterInsights/, :fingerprint_name => "MonsterInsights plugin"},
      {:regex => /optimizely/, :fingerprint_name => "Optimizely"},
      {:regex => /trackalyze/, :fingerprint_name => "Trackalyze"},
      {:regex => /doubleclick.net|googleadservices/, :fingerprint_name => "Google Ads"},
      {:regex => /munchkin.js/, :fingerprint_name => "Marketo"},
      {:regex => /omniture/, :fingerprint_name => "Omniture"},
      {:regex => /w._hsq/, :fingerprint_name => "Hubspot"},
      {:regex => /Async HubSpot Analytics/, :fingerprint_name => "Async HubSpot Analytics Code for WordPress"},
      {:regex => /Olark live chat software/, :fingerprint_name => "Olark"},
      {:regex => /intercomSettings/, :fingerprint_name => "Intercom"},
      {:regex => /vidyard/, :fingerprint_name => "Vidyard"},

      ### External accounts
      {:regex => /http:\/\/www.twitter.com.*?/, :fingerprint_name => "Twitter"},
      {:regex => /http:\/\/www.facebook.com.*?/, :fingerprint_name => "Facebook"},
      {:regex => /googleadservices/, :fingerprint_name => "Google Ads"},

      ### Libraries / Base Technologies
      {:regex => /jquery.js/, :fingerprint_name => "JQuery"},
      {:regex => /bootstrap.css/, :fingerprint_name => "Bootstrap"},


      ### Platforms
      {:regex => /[W|w]ordpress/, :fingerprint_name => "Wordpress"},
      {:regex => /[D|d]rupal/, :fingerprint_name => "Drupal"},
      {:regex => /[C|c]loudflare/, :fingerprint_name => "Cloudflare"},


      ### Provider
      #{:regex => /Content Delivery Network via Amazon Web Services/, :fingerprint_name => "Amazon CDN"},

      ### Wordpress Plugins
      #{ :regex => /wp-content\/plugins\/.*?\//, :fingerprint_name => "Wordpress Plugin" },
      #{ :regex => /xmlrpc.php/, :fingerprint_name => "Wordpress API"},
      #{ :regex => /Yoast SEO Plugin/, :fingerprint_name => "Wordpress: Yoast SEO Plugin"},
      #{ :regex => /All in One SEO Pack/, :fingerprint_name => "Wordpress: All in One SEO Pack"},
      #{:regex => /PowerPressPlayer/, :fingerprint_name => "Powerpress Wordpress Plugin"}
      ]
    ###

    stack = []

    # Iterate through the target strings, which can be found in the web mixin
    http_body_checks.each do |check|
      matches = response.body.scan(check[:regex])

      # Iterate through all matches
      matches.each do |match|
        stack << check[:fingerprint_name]
      end if matches
    end
    # End interation through the target strings
    ###
  stack
  end

  def _check_uri(uri)
    _log "_check_uri called"
    temp = []
    temp << "ASP Classic" if uri =~ /.*\.asp(\?.*)?$/i
    temp << "ASP.NET" if uri =~ /.*\.aspx(\?.*)?$/i
    temp << "CGI" if uri =~ /.*\.cgi(\?.*)?$/i
    temp << "Java (JSESSIONID)" if uri =~ /jsessionid=/i
    temp << "JSP" if uri =~ /.*\.jsp(\?.*)?$/i
    temp << "PHP" if uri =~ /.*\.php(\?.*)?$/i
    temp << "Struts" if uri =~ /.*\.do(\?.*)?$/i
    temp << "Struts" if uri =~ /.*\.go(\?.*)?$/i
    temp << "Struts" if uri =~ /.*\.action(\?.*)?$/i
  temp
  end

  def _check_generator(response)
    _log "_check_generator called"
    temp = []

    # Example: <meta name="generator" content="MediaWiki 1.29.0-wmf.9"/>
    doc = Nokogiri.HTML(response.body)
    doc.xpath("//meta[@name='generator']/@content").each do |attr|
      temp << attr.value
    end

    _log "Returning: #{temp}"

  temp
  end

  def _gather_cookies(response)
    header = response.header['set-cookie']
  end

  def _check_cookies(response)
    _log "_check_cookies called"

    temp = []

    header = response.header['set-cookie']
    if header

      temp << "Apache JServ" if header =~ /^.*JServSessionIdroot.*$/
      temp << "ASP.NET" if header =~ /^.*ASPSESSIONID.*$/
      temp << "ASP.NET" if header =~ /^.*ASP.NET_SessionId.*$/
      temp << "BEA WebLogic" if header =~ /^.*WebLogicSession*$/
      temp << "BigIP" if header =~ /^.*BIGipServer*$/
      temp << "Coldfusion" if header =~ /^.*CFID.*$/
      temp << "Coldfusion" if header =~ /^.*CFTOKEN.*$/
      temp << "Coldfusion" if header =~ /^.*CFGLOBALS.*$/
      temp << "Coldfusion" if header =~ /^.*CISESSIONID.*$/
      temp << "ExpressJS" if header =~ /^.*connect.sid.*$/
      temp << "IBM WebSphere" if header =~ /^.*sesessionid.*$/
      temp << "IBM Tivoli" if header =~ /^.*PD-S-SESSION-ID.*$/
      temp << "IBM Tivoli" if header =~ /^.*PD_STATEFUL.*$/
      temp << "Mint" if header =~ /^.*MintUnique.*$/
      temp << "Moodle" if header =~ /^.*MoodleSession.*$/
      temp << "Omniture" if header =~ /^.*sc_id.*$/
      temp << "PHP" if header =~ /^.*PHPSESSION.*$/
      temp << "PHP" if header =~ /^.*PHPSESSID.*$/
      temp << "Spring" if header =~ /^.*JSESSIONID.*$/
      temp << "Yii PHP Framework 1.1.x" if header =~ /^.*YII_CSRF_TOKEN.*$/       # https://github.com/yiisoft/yii
      temp << "MediaWiki" if header =~ /^.*wiki??_session.*$/

    end

    _log "Cookies: #{temp}"

    temp
  end




  def _check_x_headers(response)
    _log "_check_x_headers called"

    temp = []

    ### X-AspNet-Version-By Header
    header = response.header['X-AspNet-Version']
    temp << "#{header}".gsub("X-AspNet-Version:","") if header

    ### X-Powered-By Header
    header = response.header['X-Powered-By']
    temp << "#{header}".gsub("X-Powered-By:","") if header

    ### Generator
    header = response.header['x-generator']
    temp << "#{header}".gsub("x-generator:","") if header

    ### x-drupal-cache
    header = response.header['x-drupal-cache']
    temp << "Drupal" if header

    header = response.header['x-batcache']
    temp << "Wordpress Hosted" if header

    header = response.header['fastly-restarts']
    temp << "Fastly CDN" if header

    # TODO - magento
    ###[_]  - x-magento-lifetime: 86400
    ###[_]  - x-magento-action: cms_index_index

    header = response.header['x-pingback']
    if header
      if "#{header}" =~ /xmlrpc.php/
        temp << "Wordpress API"
      else
        _log_error "Got x-pingback header: #{header}, but can't do anything with it"
      end
    end

    _log "Returning: #{temp}"
  temp
  end

  def _check_server_header(response, response2)
    _log "_check_server_header called"

    ### Server Header
    server_header = _resolve_server_header(response.header['server'])

    if server_header
      # If we got the same 'server' header in both, create a WebServer entity
      # Checking for both gives us some assurance it's not totally bogus (e)
      # TODO: though this might miss something if it's a different resolution path?
      if response.header['server'] == response2.header['server']
        _log "Returning: #{server_header}"

        return server_header
      else
        _log_error "Header did not match!"
        _log_error "1: #{response.header['server']}"
        _log_error "2: #{response2.header['server']}"
      end
    else
      _log_error "No 'server' header!"
    end

  return nil
  end

  # This method resolves a header to a probable name in the case of generic
  # names. Otherwise it just matches what was sent.
  def _resolve_server_header(header_content)
    return nil unless header_content

    # Sometimes we're given a generic name, so keep track of the probable server for that name
    aliases = [
      {:given => "Server", :probably => "Apache (Server)"}
    ]

    # Set the default
    web_server_name = header_content

    # Check all aliases, returning the probable name if it matches exactly
    aliases.each do |a|
      web_server_name = a[:probably] if a[:given] =~ /#{Regexp.escape(header_content)}/
    end

    _log "Resolved: #{web_server_name}"

  web_server_name
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

  def create_weak_cipher_issue
    _create_issue({
      name: "Weak Ciphers enabled on #{uri}",
      type: "weak_cipher_suite",
      severity: 5,
      status: "confirmed",
      description: "This server is configured to allow a known-weak cipher suite",
      recommendation: "Disable the weak ciphers.",
      references: [
        "https://thycotic.com/company/blog/2014/05/16/ssl-beyond-the-basics-part-2-ciphers/"
      ],
      details: { allowed_ciphers: accepted_ciphers }
    })
  end

end
end
end
end