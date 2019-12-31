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
      :example_entities => [
        {"type" => "Uri", "details" => {"name" => "https://intrigue.io"}}],
      :allowed_options => [],
      :created_types => []
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

    _log "Making initial requests"
    # Grab the full response
    response = http_request :get, uri
    response2 = http_request :get, uri

    unless response && response2 && response.body
      _log_error "Unable to receive a response for #{uri}, bailing"
      return
    end

    response_data_hash = Digest::SHA256.base64digest(response.body)

    # we can check the existing response, so send that
    _log "Checking if API Endpoint"
    api_enabled = check_api_endpoint(response)

    # we can check the existing response, so send that
    _log "Checking if Forms"
    contains_forms = check_forms(response.body)

    # we'll need to make another request
    _log "Checking OPTIONS"
    verbs_enabled = check_options_endpoint(uri)

    # grab all script_references
    _log "Parsing out Scripts"
    script_links = response.body.scan(/<script.*?src=["|'](.*?)["|']/).map{|x| x.first if x }

    # save the Headers
    headers = []
    _log "Saving Headers"
    response.each_header{|x| headers << "#{x}: #{response[x]}" }

    # Use intrigue-ident code to request all of the pages we
    # need to properly fingerprint
    _log "Attempting to fingerprint (without the browser)!"
    ident_matches = generate_http_requests_and_check(uri,false) || {}

    ident_fingerprints = ident_matches["fingerprint"] || []
    ident_content_checks = ident_matches["content"] || []
    _log "Got #{ident_fingerprints.count} fingerprints!"

    # get the request/response we made so we can keep track of redirects
    ident_responses = ident_matches["responses"]
    _log "Received #{ident_responses.count} responses for fingerprints!"

    if ident_fingerprints.count > 0
      _log "Attempting to match to vulnerabilities!"
      # Make sure the key is set before querying intrigue api
      vulndb_api_key = _get_task_config "intrigue_vulndb_api_key"
      use_api = vulndb_api_key && vulndb_api_key.length > 0
      ident_fingerprints = ident_fingerprints.map do |fp|

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
        _create_content_issue(uri, c)
      end
    end

    # if we ever match something we know the user won't
    # need to see (aka the fingerprint's :hide parameter is true), go ahead
    # and hide the entity... meaning no recursion and it shouldn't show up in
    # the UI / queries if any of the matches told us to hide the entity, do it.
    # EXAMPLE TEST CASE: http://103.24.203.121:80 (cpanel missing page)
    if ident_fingerprints.detect{|x| x["hide"] == true }
      _log "Entity hidden based on fingerprint"
      @entity.hidden = true
      @entity.save_changes
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
        cert = connect_ssl_socket_get_cert(hostname,port)
        if cert 
          alt_names = parse_names_from_cert(cert)
        else
          alt_names = []
        end

        _log "Got cert's alt names: #{alt_names}"

        if set_cookie
          _log "Secure Cookie: #{set_cookie.split(";").detect{|x| x =~ /secure/i }}"
          _log "Httponly Cookie: #{set_cookie.split(";").detect{|x| x =~ /httponly/i }}"

          # check for authentication and if so, bump the severity
          auth_endpoint = ident_content_checks.select{|x|
            x["result"]}.join(" ") =~ /Authentication/

          if auth_endpoint
            # create an issue if not detected
            if !(set_cookie.split(";").detect{|x| x =~ /httponly/i })
              # 4 since we only create an issue if it's an auth endpoint
              severity = 4
              _create_missing_cookie_attribute_http_only_issue(uri, set_cookie)
            end

            if !(set_cookie.split(";").detect{|x| x =~ /secure/i } )
              # set a default,4 since we only create an issue if it's an auth endpoint
              severity = 4
              _create_missing_cookie_attribute_secure_issue(uri, set_cookie)
            end

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
            (x[:version] =~ /SSL/ || x[:version] == "TLSv1") }
          _create_deprecated_protocol_issue(uri, accepted_connections)
        end

      else # http endpoint, just check for httponly

        if set_cookie
          _log "Httponly Cookie: #{set_cookie.split(";").detect{|x| x =~ /httponly/i }}"

          # create an issue if not detected
          if !set_cookie.split(";").detect{|x| x =~ /httponly/i }
            _create_missing_cookie_attribute_http_only_issue(uri, set_cookie)
          end
        end

        alt_names = []

      end

    end

    ###
    ### get the favicon & hash it
    ###
    _log "Getting Favicon"
    favicon_response = http_request(:get, "#{uri}/favicon.ico")

    if favicon_response && favicon_response.code == "200"
      favicon_data = Base64.strict_encode64(favicon_response.body)
      favicon_md5 = Digest::MD5.hexdigest(favicon_response.body)
      favicon_sha1 = Digest::SHA1.hexdigest(favicon_response.body)
    # else
    #
    # <link rel="shortcut icon" href="https://static.dyn.com/static/ico/favicon.1d6c21680db4.ico"/>
    # try link in the body
    # TODO... maybe this should be the other way around?
    #
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
    _log "Matching to products"
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
        "favicon_md5" => favicon_md5,
        "favicon_sha1" => favicon_sha1,
        "generator" => generator_string,
        "verbs" => verbs_enabled,
        "scripts" => script_links,
        "headers" => headers,
        "cookies" => response.header['set-cookie'],
        "forms" => contains_forms,
        "response_data_hash" => response_data_hash,
        "hidden_favicon_data" => favicon_data,
        "extended_favicon_data" => favicon_data,
        "hidden_response_data" => response.body,
        "extended_full_responses" => ident_responses, # includes all the redirects etc
        "extended_response_body" => response.body,
        "products" => products.compact,
        "fingerprint" => ident_fingerprints.uniq,
        "content" => ident_content_checks.uniq,
        "extended_configuration" => ident_content_checks.uniq, # new content field
        "ciphers" => accepted_connections,
        "extended_ciphers" => accepted_connections # new ciphers field
      })

      # Set the details, and make sure raw response data is a hidden (not searchable) detail
      @entity.set_details new_details
    end

    # Check for other entities with this same response hash
    _log "Attempting to identify aliases"
    Intrigue::Model::Entity.scope_by_project_and_type(
      @entity.project.name,"Uri").each do |e|
      next if @entity.id == e.id

      # Do some basic up front checking
      # TODO... make this a filter using JSONb in postgres
      old_title = e.get_detail("title")
      unless "#{title}".strip.sanitize_unicode == "#{old_title}".strip.sanitize_unicode
        _log "Skipping #{e.name}, title doesnt match (#{old_title})"
        next
      end

      unless response.code == e.get_detail("code")
        _log "Skipping #{e.name}, code doesnt match"
        next
      end

      _log "Checking match candidate: #{e.name} #{e.get_detail("title")}"

      # parse our content with Nokogiri
      #our_doc = Nokogiri::HTML(open(a));nil
      our_doc = "#{response.body}".sanitize_unicode

      # parse them
      #their_doc = Nokogiri::HTML(open(b));nil
      their_doc = e.details["hidden_response_data"]

      # compare them
      diffs = parse_html_diffs(our_doc,their_doc)

      # if they're the same, alias
      if diffs.empty?
        _log "No difference, match found!! Attaching to entity: #{e.name}"
        e.alias_to @entity.alias_group_id
      else
        _log  "HTML Content Diffs for #{e.name}"
        diffs.each do |d|
          _log "DIFF #{d}"
        end
      end
    end

  end

  def _gather_supported_ciphers(hostname,port)
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

end
end
end
end