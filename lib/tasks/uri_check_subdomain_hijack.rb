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
      
      elsif response.body =~ /Repository not found/i
        _create_hijackable_subdomain_issue "Bitbucket", uri, "potential"
      
      elsif response.body =~ /Trying to access your account\?/i
        _create_hijackable_subdomain_issue "CampaignMonitor", uri, "potential"
      
      #elsif response.body =~ /404 Not Found/i # TODO... check uri && file against alias groups?
      #  _create_hijackable_subdomain_issue "CargoCollective | Fly.io | Netlify", uri, "potential"  
      
      # TODO ... digital ocean https://github.com/EdOverflow/can-i-take-over-xyz

      elsif response.body =~ /Fastly error: unknown domain/i
        _create_hijackable_subdomain_issue "Fastly", uri, "potential"      

      elsif response.body =~ /The feed has not been found\./i
        _create_hijackable_subdomain_issue "Feedpress", uri, "potential"      
      
      elsif response.body =~ /\<title\>Flywheel - Unknown Domain/i
        _create_hijackable_subdomain_issue "Flywheel", uri, "potential"

      elsif response.body =~ /The thing you were looking for is no longer here, or never was/i
        _create_hijackable_subdomain_issue "Ghost", uri, "potential"
      
      elsif response.body =~ /There isn\'t a Github Pages site here/i
        _create_hijackable_subdomain_issue "Github", uri, "potential"
      
      elsif response.body =~ /404 Blog is not found/i
        _create_hijackable_subdomain_issue "", uri, "potential"

      elsif response.body =~ /No such app/i 
        if !(uri =! /heroku.com/ || uri =~ /herokussl.com/ || uri =~ /herokudns.com/ || uri =~ /herokuapp.com/) 
          _create_hijackable_subdomain_issue "Heroku", uri, "potential"
        end
        
      elsif response.body =~ /No settings were found for this company:/i
        _create_hijackable_subdomain_issue "Help Scout", uri, "potential"
      
      elsif response.body =~ /We could not find what you're looking for\./i
        _create_hijackable_subdomain_issue "Help Juice", uri, "potential"

      elsif response.body =~ /Uh oh. That page doesn\'t exist/i
        _create_hijackable_subdomain_issue "Intercom", uri, "potential"

      elsif response.body =~ /is not a registered InCloud YouTrack/i
        _create_hijackable_subdomain_issue "JetBrains", uri, "potential"

      elsif response.body =~ /No Site For Domain/i
        _create_hijackable_subdomain_issue "Kinsta", uri, "potential"

      elsif response.body =~ /It looks like you may have taken a wrong turn somewhere/i
        _create_hijackable_subdomain_issue "LaunchRock", uri, "potential"
      
      elsif response.body =~ /Unrecognized domain/i
        _create_hijackable_subdomain_issue "Mashery", uri, "potential"
      
      elsif response.body =~ /404 error unknown site\!/i
        _create_hijackable_subdomain_issue "Pantheon", uri, "potential"
      
      elsif response.body =~ /Project doesnt exist... yet!/i
        _create_hijackable_subdomain_issue "Readme.io", uri, "potential"

      elsif response.body =~ /Sorry, this shop is currently unavailable./i
        _create_hijackable_subdomain_issue "Shopify", uri, "potential"

      elsif response.body =~ /<title>Statuspage \| Hosted Status Page/i
        _create_hijackable_subdomain_issue "Statuspage", uri, "potential"

      #elsif response.body =~ /page not found/i
      #  _create_hijackable_subdomain_issue "Strikingly", uri, "potential"

      elsif response.body =~ /project not found/i
        _create_hijackable_subdomain_issue "Surge.sh", uri, "potential"

      elsif response.body =~ /Whatever you were looking for doesn\'t currently exist at this address/i
        _create_hijackable_subdomain_issue "Tumblr", uri, "potential"

      elsif response.body =~ /Please renew your subscription/i
        _create_hijackable_subdomain_issue "Tilda", uri, "potential"

      elsif response.body =~ /page not found/i
        _create_hijackable_subdomain_issue "UptimeRobot", uri, "potential"        

      elsif response.body =~ /This UserVoice subdomain is currently available\!/i
        _create_hijackable_subdomain_issue "UserVoice", uri, "potential"	

      elsif response.body =~ /domain is already connected to a Webflow site/i
        _create_hijackable_subdomain_issue "Webflow", uri, "potential"	

      elsif response.body =~ /Do you want to register \*\.wordpress\.com/i
        _create_hijackable_subdomain_issue "Wordpress", uri, "potential"	
       
      # disabled per https://github.com/EdOverflow/can-i-take-over-xyz
      #elsif response.body =~ /This domain is successfully pointed at WP Engine, but is not configured/i
      #  _create_hijackable_subdomain_issue "WPEngine", uri, "potential"
    
      end
    end
      
  end #end run

  def _create_hijackable_subdomain_issue type, uri, status, severity=2
    _create_issue({
      name: "Subdomain Hijacking Detected (#{type})",
      type: "subdomain_hijack_detected",
      severity: severity,
      status: status,
      description:  "This uri #{uri} appears to be unclaimed on a third party host, meaning," +
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
