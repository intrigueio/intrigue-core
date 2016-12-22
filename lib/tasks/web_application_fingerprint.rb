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

    server_header = resolve_header_name(response.header['server'])
    if server_header =~ /Zend/
      _create_entity "WebApplication", {
        :name => "Zend",
        :uri => "#{web_application_name}"
      }
    end

    ### X-Powered-By Header
    header = response.header['X-AspNet-Version']
    if server_header =~ /ASP\.NET/
      _create_entity "WebApplication", {
        :name => "#{header}".gsub("X-AspNet-Version:",""),
        :uri => "#{web_application_name}"
      }
    elsif server_header =~ /PHP/
        _create_entity "WebApplication", {
          :name => "#{header}",
          :uri => "#{web_application_name}"
        }
    end

    ### X-Powered-By Header
    header = response.header['X-Powered-By']
    if server_header =~ /ASP\.NET/
      _create_entity "WebApplication", {
        :name => "#{header}".gsub("X-Powered-By:",""),
        :uri => "#{web_application_name}"
      }
    end

    _log "Headers:\n #{response.to_hash.inspect}"
    _log "Content:\n #{response.body.inspect}"


  end

  # This method resolves a header to a probable name in the case of generic
  # names. Otherwise it just matches what was sent.
  def resolve_header_name(header_content)

    # Sometimes we're given a generic name, so keep track of the probable server for that name
    aliases = [
      {:given => "Server", :probably => "Apache"}
    ]

    # Set the default
    web_server_name = header_content

    # Check all aliases, returning the probably name if it matches exactly
    aliases.each { |a| web_server_name = a[:probably] if a[:given] == header_content }

  web_server_name
  end

end
end
