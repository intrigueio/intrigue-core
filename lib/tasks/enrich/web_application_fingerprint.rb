module Intrigue
class WebApplicationFingerprint < BaseTask
  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "web_application_fingerprint",
      :pretty_name => "Web Application Fingerprint",
      :authors => ["jcran"],
      :description => "Web Application Fingerprint",
      :references => [
        "http://www.net-square.com/httprint_paper.html",
        "https://www.troyhunt.com/shhh-dont-let-your-response-headers/",
        "https://asafaweb.com/",
        "https://www.owasp.org/index.php/Category:OWASP_Cookies_Database"
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

    ### Server Header
    applications = []

    response.each_header {|h,v| _log "#{h}: #{v}" }

    ### X-AspNet-Version-By Header
    header = response.header['X-AspNet-Version']
    if header
      applications << "#{header}".gsub("X-AspNet-Version:","")
    end

    ### X-Powered-By Header
    header = response.header['X-Powered-By']
    if header
      applications << "#{header}".gsub("X-Powered-By:","")
    end

    ### Generator
    header = response.header['x-generator']
    if header
      applications << "#{header}".gsub("x-generator:","")
    end

    ### x-drupal-cache
    header = response.header['x-drupal-cache']
    if header
      applications << "Drupal"
    end

    ### set-cookie
    header = response.header['set-cookie']
    if header

      applications << "Apache JServ" if header =~ /^.*JServSessionIdroot.*$/
      applications << "ASP.NET" if header =~ /^.*ASPSESSIONID.*$/
      applications << "ASP.NET" if header =~ /^.*ASP.NET_SessionId.*$/
      applications << "BEA WebLogic" if header =~ /^.*WebLogicSession*$/
      applications << "Coldfusion" if header =~ /^.*CFID.*$/
      applications << "Coldfusion" if header =~ /^.*CFTOKEN.*$/
      applications << "Coldfusion" if header =~ /^.*CFGLOBALS.*$/
      applications << "Coldfusion" if header =~ /^.*CISESSIONID.*$/
      applications << "ExpressJS" if header =~ /^.*connect.sid.*$/
      applications << "IBM WebSphere" if header =~ /^.*sesessionid.*$/
      applications << "IBM Tivoli" if header =~ /^.*PD-S-SESSION-ID.*$/
      applications << "IBM Tivoli" if header =~ /^.*PD_STATEFUL.*$/
      applications << "J2EE" if header =~ /^.*JSESSIONID.*$/
      applications << "Mint" if header =~ /^.*MintUnique.*$/
      applications << "Omniture" if header =~ /^.*sc_id.*$/
      applications << "PHP" if header =~ /^.*PHPSESSION.*$/
      applications << "MediaWiki" if header =~ /^.*wiki??_session.*$/

    end

    _log "Setting applications to #{applications.sort.uniq}"

    @entity.details["web_application"] = applications.sort.uniq
    @entity.save

  end

end
end
