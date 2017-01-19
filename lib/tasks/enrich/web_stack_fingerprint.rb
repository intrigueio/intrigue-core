module Intrigue
class WebStackFingerprint < BaseTask
  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "web_stack_fingerprint",
      :pretty_name => "Web Stack Fingerprint",
      :authors => ["jcran"],
      :description => "Sets the \"stack\" detail, letting us know about the web stack of the target.",
      :references => [
        "http://www.net-square.com/httprint_paper.html",
        "https://www.troyhunt.com/shhh-dont-let-your-response-headers/",
        "https://asafaweb.com/",
        "https://www.owasp.org/index.php/Category:OWASP_Cookies_Database",
        "http://stackoverflow.com/questions/31134333/this-application-has-no-explicit-mapping-for-error"
      ],
      :type => "enrichment",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [{"type" => "Uri", "attributes" => {"name" => "https://intrigue.io"}}],
      :allowed_options => [],
      :created_types => ["WebServer"]
    }
  end

  def run
    super
    # Grab the full response 2x
    uri = _get_entity_name

    web_application_name = uri.split('/')[0,3].join('/')

    response = http_get uri
    response2 = http_get uri

    ## Indicatiors
    # Banner Grabbing / Headers (Server, X-Powered-By, X-AspNet-Version)
    # Specific Pages (trace.axd)
    # WebServer: Request/Response deviations
    # WebServer: Wrong HTTP version requests
    # WebServer: Wrong protocol s/HTTP/JUNK/g version requests
    # General fingerprinting takes all of these into account

    unless response && response2
      _log_error "Unable to receive a response for #{uri}, bailing"
      return
    end

    _log "Response #1 :"
    response.each_header {|h,v| _log "(#1) #{h}: #{v}" }
    #_log "Response #2 :"
    #response2.each_header {|h,v| _log "(#2) #{h}: #{v}" }

    ## empty stack to start
    stack = []

    stack << _check_server_header(response, response2)
    stack.concat _check_x_headers(response)
    stack.concat _check_cookies(response)
    stack.concat _check_page_content(uri)

    _log "Setting stack to #{stack.sort.uniq}"

    @entity.details["stack"] = stack.sort.uniq
    @entity.save
  end

  private

    def _check_page_content(uri)
      temp = []

      checks = [{
        :uri => "#{uri}/error",
        :content_check => /{"timestamp":\d.*,"status":999,"error":"None","message":"No message available"}/,
        :check_name => "Spring MVC",
        :check_description => "Standard Spring MVC error page",
        :test_site => "https://pcr.apple.com"
      }]

      checks.each do |check|
        response = http_get "#{check[:uri]}"
        if check[:content_check]
          if "#{response.body}" =~ /#{check[:content_check]}/
            temp << check[:check_name]
          end
        end
      end

    temp
    end

    def _check_cookies(response)
      temp = []

      header = response.header['set-cookie']
      if header

        temp << "Apache JServ" if header =~ /^.*JServSessionIdroot.*$/
        temp << "ASP.NET" if header =~ /^.*ASPSESSIONID.*$/
        temp << "ASP.NET" if header =~ /^.*ASP.NET_SessionId.*$/
        temp << "BEA WebLogic" if header =~ /^.*WebLogicSession*$/
        temp << "Coldfusion" if header =~ /^.*CFID.*$/
        temp << "Coldfusion" if header =~ /^.*CFTOKEN.*$/
        temp << "Coldfusion" if header =~ /^.*CFGLOBALS.*$/
        temp << "Coldfusion" if header =~ /^.*CISESSIONID.*$/
        temp << "ExpressJS" if header =~ /^.*connect.sid.*$/
        temp << "IBM WebSphere" if header =~ /^.*sesessionid.*$/
        temp << "IBM Tivoli" if header =~ /^.*PD-S-SESSION-ID.*$/
        temp << "IBM Tivoli" if header =~ /^.*PD_STATEFUL.*$/
        temp << "J2EE" if header =~ /^.*JSESSIONID.*$/
        temp << "Mint" if header =~ /^.*MintUnique.*$/
        temp << "Omniture" if header =~ /^.*sc_id.*$/
        temp << "PHP" if header =~ /^.*PHPSESSION.*$/
        temp << "MediaWiki" if header =~ /^.*wiki??_session.*$/

      end

      _log "Got: #{temp} due to cookies!"

      temp
    end

    def _check_x_headers(response)
      temp = []

      ### X-AspNet-Version-By Header
      header = response.header['X-AspNet-Version']
      if header
        temp << "#{header}".gsub("X-AspNet-Version:","")
      end

      ### X-Powered-By Header
      header = response.header['X-Powered-By']
      if header
        temp << "#{header}".gsub("X-Powered-By:","")
      end

      ### Generator
      header = response.header['x-generator']
      if header
        temp << "#{header}".gsub("x-generator:","")
      end

      ### x-drupal-cache
      header = response.header['x-drupal-cache']
      if header
        temp << "Drupal"
      end

    temp
    end

    def _check_server_header(response, response2)
      ### Server Header
      server_header = _resolve_server_header(response.header['server'])

      if server_header
        # If we got the same 'server' header in both, create a WebServer entity
        # Checking for both gives us some assurance it's not totally bogus (e)
        # TODO: though this might miss something if it's a different resolution path?
        if response.header['server'] == response2.header['server']
          _log_good "Creating header for #{server_header}"
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

      # Sometimes we're given a generic name, so keep track of the probable server for that name
      aliases = [
        {:given => "Server", :probably => "Apache"}
      ]

      # Set the default
      web_server_name = header_content

      # Check all aliases, returning the probably name if it matches exactly
      aliases.each { |a| web_server_name = a[:probably] if a[:given] =~ /#{header_content}/ }

      _log "Resolved: #{web_server_name}"

    web_server_name
    end

end
end
