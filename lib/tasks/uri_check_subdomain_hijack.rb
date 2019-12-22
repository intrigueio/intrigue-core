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
        _create_hijackable_subdomain_issue "AWS S3", uri, "potential"
      elsif response.body =~ /^Repository not found$/i
        _create_hijackable_subdomain_issue "Bitbucket", uri, "potential"
      elsif response.body =~ /^Trying to access your account\?$/i
        _create_hijackable_subdomain_issue "CampaignMonitor", uri, "potential"
      elsif response.body =~ /^404 Not Found$/i # TODO... check uri && file against alias groups?
        _create_hijackable_subdomain_issue "CargoCollective", uri, "potential"
      elsif response.body =~ /^The feed has not been found\.$/i
        _create_hijackable_subdomain_issue "Feedpress", uri, "potential"
      elsif response.body =~ /^Not Found$/i  # TODO... check uri && file against alias groups?
        # This could also be fly.io 
        if uri != /fly.io/ 
          _create_hijackable_subdomain_issue "Fly.io", uri, "potential"
        end
      elsif response.body =~ /The thing you were looking for is no longer here, or never was/i
        _create_hijackable_subdomain_issue "Ghost", uri, "potential"
      elsif response.body =~ /There isn't a Github Pages site here/i
        _create_hijackable_subdomain_issue "Github", uri, "potential"
      elsif response.body =~ /No such app/i 
        if !(uri =! /heroku.com/ || uri =~ /herokussl.com/ || uri =~ /herokudns.com/ || uri =~ /herokuapp.com/) 
          _create_hijackable_subdomain_issue "Heroku", uri, "potential"
        end
      elsif response.body =~ /No settings were found for this company:/i
        _create_hijackable_subdomain_issue "Help Scout", uri, "potential"
      elsif response.body =~ /We could not find what you're looking for\./i
        _create_hijackable_subdomain_issue "Help Juice", uri, "potential"
      elsif response.body =~ /is not a registered InCloud YouTrack/i
        _create_hijackable_subdomain_issue "JetBrains", uri, "potential"
      elsif response.body =~ /Uh oh. That page doesn\'t exist/i
        _create_hijackable_subdomain_issue "Intercom", uri, "potential"
      elsif response.body =~ /Unrecognized domain/i
        _create_hijackable_subdomain_issue "Mashery", uri, "potential"
      elsif response.body =~ /^Not Found$/i  # TODO... check uri && file against alias groups?
        if uri == /netlify.com/ 
          _create_hijackable_subdomain_issue "Netlify", uri, "potential"
        end
      elsif response.body =~ /Project doesnt exist... yet!/i
        _create_hijackable_subdomain_issue "Readme.io", uri, "potential"
      elsif response.body =~ /This domain is successfully pointed at WP Engine, but is not configured/i
        _create_hijackable_subdomain_issue "WPEngine", uri, "potential"
      # currently disabled, see: https://github.com/EdOverflow/can-i-take-over-xyz/issues/11
      #elsif response.body =~ /The requested URL was not found on this server./
      #  _create_hijackable_subdomain_issue "Unbounce", uri, "potential"
      end
    end
      
  end #end run

end
end
end
