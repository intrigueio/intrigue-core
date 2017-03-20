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
      :created_types => []
    }
  end

  def run
    super
    # Grab the full response 2x
    uri = _get_entity_name

    response = http_get uri
    response2 = http_get uri

    ## Indicators
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

    _log "Server response:"
    response.each_header {|h,v| _log " - #{h}: #{v}" }

    ## empty stack to start
    stack = []

    # Use various techniques to build out a "stack"
    stack << _check_server_header(response, response2)
    stack.concat _check_x_headers(response)
    stack.concat _check_cookies(response)
    stack.concat _check_generator(response)
    stack.concat _check_uri(uri)
    stack.concat _check_specific_pages(uri)

=begin
    TODO - integrate this work from Intrigue::Task::Web
    # Iterate through the target strings, which can be found in the web mixin
    http_body_checks.each do |check|
      matches = contents.scan(check[:regex])

      # Iterate through all matches
      matches.each do |match|
       _create_entity("SoftwarePackage",
        { "name" => "#{check[:finding_name]}",
          "uri" => "#{uri}",
          "content" => "Found #{match} on #{uri}" })
      end if matches
    end
    # End interation through the target strings
=end

    clean_stack = stack.select{ |x| x != nil }.uniq
    _log "Setting stack to #{clean_stack}"

    @entity.lock!
    @entity.update(:details => @entity.details.merge("stack" => clean_stack))

  end

  private

  def _check_uri(uri)
    _log "_check_uri called"
    temp = []
    temp << "ASP Classic" if uri =~ /.*\.asp$/i
    temp << "ASP.NET" if uri =~ /.*\.aspx$/i
    temp << "CGI" if uri =~ /.*\.cgi$/i
    temp << "Java (jsessionid)" if uri =~ /jsessionid=/i
    temp << "JSP" if uri =~ /.*\.jsp$/i
    temp << "PHP" if uri =~ /.*\.php$/i
    temp << "Struts" if uri =~ /.*\.do$/i
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


    def _check_specific_pages(uri)
      _log "_check_specific_pages called"
      temp = []

      all_checks = [
        {
          :uri => "#{uri}",
          :checklist => [
          {
            :name => "ASP.Net", # won't be used if we have
            :description => "ASP.Net Error Message",
            :type => "content",
            :content => /ASP.NET is configured/,
            :test_site => "http://54.225.111.54",
            :dynamic_name => lambda{|x| x.scan(/ASP.NET Version:.*$/)[0].gsub("ASP.NET Version:","").chomp }
          },
          {
            :name => "LimeSurvey", # won't be used if we have
            :description => "LimeSurvey",
            :type => "content",
            :content => /Donate to LimeSurvey/,
            :test_site => "http://129.186.73.249/index.php/admin"
          },
          {
            :name => "MediaWiki", # won't be used if we have
            :description => "Powered by MediaWiki ",
            :type => "content",
            :content => /<a href="\/\/www.mediawiki.org\/">Powered by MediaWiki<\/a>/,
            :test_site => "https://manual.limesurvey.org"
          },
          {
            :name => "Tomcat", # won't be used if we have
            :description => "Tomcat Web Application Server",
            :type => "content",
            :content => /<title>Apache Tomcat/,
            :test_site => "https://cms.msu.montana.edu/",
            :dynamic_name => lambda{|x| x.scan(/<title>.*<\/title>/)[0].gsub("<title>","").gsub("</title>","").chomp }
          },
          {
            :name => "Yoast Wordpress SEO Plugin", # won't be used if we have
            :description => "Yoast Wordpress SEO Plugin",
            :type => "content",
            :content => /<!-- \/ Yoast WordPress SEO plugin. -->/,
            :test_site => "https://ip-50-62-231-56.ip.secureserver.net",
            :dynamic_name => lambda{|x| x.scan(/the Yoast WordPress SEO plugin v.* - h/)[0].gsub("the ","").gsub(" - h","") }
          }
        ]},
        {
          :uri => "#{uri}/error",
          :checklist => [{
            :name => "Spring MVC",
            :description => "Standard Spring MVC error page",
            :type => "content",
            :content => /{"timestamp":\d.*,"status":999,"error":"None","message":"No message available"}/,
            :test_site => "https://pcr.apple.com"
        }]},
        {
          :uri => "#{uri}/xmlrpc.php",
          :checklist => [{
            :name => "XMLRPC API",
            :description => "Standard Blog API page",
            :type => "content",
            :content => /XML-RPC server accepts POST requests only./,
            :test_site => "https://ip-50-62-231-56.ip.secureserver.net/xmlrpc.php"
        }]}
      ]

      all_checks.each do |check|
        response = http_get "#{check[:uri]}"
        if response

          #### iterate on checks for this URI
          check[:checklist].each do |check|

            # Content checks first
            if check[:type] == "content"

              # Do each content check, call the dynamic name if we have it,
              # otherwise, just give it a static name
              if "#{response.body}" =~ /#{check[:content]}/
                if check[:dynamic_name]
                  temp << check[:dynamic_name].call(response.body)
                else
                  temp << check[:name]
                end
              end

            else
              # other types might include image check
              raise "Not sure how to handle this check type"
            end


          end
        end
      end

      _log "Returning: #{temp}"
    temp
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
        temp << "J2EE" if header =~ /^.*JSESSIONID.*$/
        temp << "Mint" if header =~ /^.*MintUnique.*$/
        temp << "Omniture" if header =~ /^.*sc_id.*$/
        temp << "PHP" if header =~ /^.*PHPSESSION.*$/
        temp << "PHP" if header =~ /^.*PHPSESSID.*$/
        # https://github.com/yiisoft/yii
        temp << "Yii PHP Framework 1.1.x" if header =~ /^.*YII_CSRF_TOKEN.*$/
        temp << "MediaWiki" if header =~ /^.*wiki??_session.*$/

      end

      _log "Returning: #{temp}"

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
