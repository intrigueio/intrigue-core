module Intrigue
module Task
class UriCheckSudomainHijack  < BaseTask

  include Intrigue::Task::Web

  def self.metadata
    {
      :name => "uri_check_subdomain_hijack",
      :pretty_name => "URI Check Subdomain Hijack",
      :authors => ["jcran"],
      :description =>   "This task checks for a specific string on a matched uri, indicating that it's a hijackable domain",
      :references => ["https://github.com/EdOverflow/can-i-take-over-xyz"],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["Uri"],
      :example_entities => [{"type" => "Uri", "details" => {"name" => "http://www.intrigue.io"}}],
      :allowed_options => [],
      :created_types => []
    }
  end

  def run
    super

    uri = _get_entity_name
    response = http_request(:get, uri)

    if response
      if response.body =~ /The specified bucket does not exist/i
        _hijackable_subdomain "AWS S3", uri, "potential"
      elsif response.body =~ /No such app/i
        _hijackable_subdomain "Heroku", uri, "potential"
      elsif response.body =~ /No settings were found for this company:/i
        _hijackable_subdomain "Help Scout", uri, "potential"
      elsif response.body =~ /We could not find what you're looking for\./i
        _hijackable_subdomain "Help Juice", uri, "potential"
      elsif response.body =~ /is not a registered InCloud YouTrack/i
        _hijackable_subdomain "JetBrains", uri, "potential"
      elsif response.body =~ /Unrecognized domain/i
        _hijackable_subdomain "Mashery", uri, "potential"
      elsif response.body =~ /Project doesnt exist... yet!/i
        _hijackable_subdomain "Readme.io", uri, "potential"
      elsif response.body =~ /This domain is successfully pointed at WP Engine, but is not configured/i
        _hijackable_subdomain "WPEngine", uri, "potential"
      end
    end
      
  end #end run

  def _hijackable_subdomain type, uri, status
      _create_issue({
        name: "Subdomain Hijacking at #{uri}",
        type: "subdomain_hijack",
        severity: 2,
        status: status,
        description:  "This uri appears to be unclaimed on a third party host, meaning," + 
                      " there's a DNS record at (#{uri}) that points to #{type}, but it" +
                      " appears to be unclaimed and you should be able to register it with" + 
                      " the host, effectively 'hijacking' the domain.",
        details: {
          uri: uri,
          type: type
        }
      })
  end

end
end
end
