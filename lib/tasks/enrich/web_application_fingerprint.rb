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
        "https://asafaweb.com/"

      ],
      :type => "discovery",
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
    @entity.details["web_application"] = []

    response.each_header {|h,v| _log "#{h}: #{v}" }

    ### X-AspNet-Version-By Header
    if response.header['X-AspNet-Version']
      header = response.header['X-AspNet-Version']
      @entity.details["web_application"] << "#{header}".gsub("X-AspNet-Version:","")
    end

    ### X-Powered-By Header
    if response.header['X-Powered-By']
      header = response.header['X-Powered-By']
      @entity.details["web_application"] << "#{header}".gsub("X-Powered-By:","")
    end

    @entity.save

  end

end
end
