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
      :references => [
        "https://github.com/EdOverflow/can-i-take-over-xyz",
        "https://github.com/projectdiscovery/nuclei-templates/blob/master/subdomain-takeover/detect-all-takeovers.yaml"
      ],
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

    # check to make sure that it's actually a DNS name
    hostname = URI.parse(uri).host
    if hostname.is_ip_address?
      _log_error "No subdomain hijack possible, this is an access-by-ip!"
      return
    end

    response_body = http_get_body(uri)

    ###
    ### Now that we know we're good to check...
    ###
    if response_body

      if response_body =~ /The specified bucket does not exist/i
        _create_hijackable_subdomain_issue "AWS S3", uri, "potential"

      elsif response_body =~ /If you are an Acquia Cloud customer and expect to see your site/i
        _create_hijackable_subdomain_issue "Acquia", uri, "potential"

      elsif response_body =~ /The site you are looking for could not be found./i
        _create_hijackable_subdomain_issue "Acquia", uri, "potential"

      elsif response_body =~ /Oops\.<\/h2><p class=\"text-muted text-tight\">The page you\'re looking for doesn/i
        _create_hijackable_subdomain_issue "Aftership", uri, "potential"

      elsif response_body =~ /Sorry, this page is no longer available./i
        _create_hijackable_subdomain_issue "AgileCRM", uri, "potential"

      elsif response_body =~ /There is no portal here \.\.\. sending you back to Aha\!/i
        _create_hijackable_subdomain_issue "Aha.io", uri, "potential"

      elsif response_body =~ /Ошибка 402. Сервис Айри.рф не оплачен/i
        _create_hijackable_subdomain_issue "Airee", uri, "potential"

      elsif response_body =~ /If this is your website and you've just created it, try refreshing in a minute/i
        _create_hijackable_subdomain_issue "Anima", uri, "potential"

      elsif response_body =~ /\<h1\>Oops\! We couldn\&\#8217\;t find that page\.<\/h1>/i
        _create_hijackable_subdomain_issue "BigCartel", uri, "potential"

      elsif response_body =~ /Repository not found/i || /The page you have requested does not exist/i
        _create_hijackable_subdomain_issue "Bitbucket", uri, "potential"

      elsif response_body =~ /<p class=\"bc-gallery-error-code\">Error Code: 404<\/p>/i
        _create_hijackable_subdomain_issue "Brightcove", uri, "potential"

      elsif response_body =~ /<strong>Trying to access your account\?<\/strong>/i
        unless (uri =~ /createsend.com/ || uri =~ /amazonaws.com/)
          _create_hijackable_subdomain_issue "CampaignMonitor", uri, "potential"
        end

      elsif response_body =~ /There is no such company. Did you enter the right URL\?/i ||
        response_body =~ /Company Not Found/i
        _create_hijackable_subdomain_issue "Canny", uri, "potential"

      elsif response_body =~ /If you\'re moving your domain away from Cargo you/i ||
        (response_body =~ /<title>404 Not Found<\/title>/ && response_body =~ /auth.cargo.site/)
        _create_hijackable_subdomain_issue "CargoCollective", uri, "potential"

      #elsif response_body =~ /404 Not Found/i # TODO... check uri && file against alias groups?
      #  _create_hijackable_subdomain_issue "CargoCollective | Fly.io | Netlify", uri, "potential"

      # TODO ... digital ocean https://github.com/EdOverflow/can-i-take-over-xyz

      elsif response_body =~ /Fastly error: unknown domain/i
        _create_hijackable_subdomain_issue "Fastly", uri, "potential" unless uri =~ /fastly.com/

      elsif response_body =~ /The feed has not been found\./i
        _create_hijackable_subdomain_issue "Feedpress", uri, "potential" unless uri =~ /feedpress.com.com/

      elsif response_body =~ /\<title\>Flywheel - Unknown Domain/i
        _create_hijackable_subdomain_issue "Flywheel", uri, "potential" unless uri =~ /flywheel.com/ || uri =~ /flywheel.io/

      # unable to verify 2020-07-21
      #elsif response_body =~ /Oops… looks like you got lost/i
      #  _create_hijackable_subdomain_issue "Frontify", uri, "potential"

      elsif response_body =~ /404: This page could not be found./i
        _create_hijackable_subdomain_issue "Gemfury", uri, "potential"

      elsif response_body =~ /With GetResponse Landing Pages, lead generation has never been easier/i
        _create_hijackable_subdomain_issue "GetRespone", uri, "potential"

      elsif response_body =~ /The thing you were looking for is no longer here/i
        _create_hijackable_subdomain_issue "Ghost", uri, "potential"

      elsif response_body =~ /There isn\'t a Github Pages site here/i
        _create_hijackable_subdomain_issue("Github", uri, "potential") unless (uri =~ /github.com/ || uri =~ /github.io/)

      ####

      #elsif response_body =~ /404 Blog is not found/i
      #  _create_hijackable_subdomain_issue "", uri, "potential"

      elsif response_body =~ /No such app/i

        if !(uri =~ /heroku.com/ || uri =~ /herokussl.com/ || uri =~ /herokudns.com/ ||
              uri =~ /herokuapp.com/ || uri =~ /amazonaws.com/)
          _create_hijackable_subdomain_issue "Heroku", uri, "potential"
        end

      elsif response_body =~ /No settings were found for this company:/i
        _create_hijackable_subdomain_issue "Help Scout", uri, "potential" unless (uri =~ /helpscoutdocs.com/ || uri =~ /amazonaws.com/)

      elsif response_body =~ /We could not find what you're looking for\./i
        _create_hijackable_subdomain_issue "Help Juice", uri, "potential"

      elsif (response_body =~ /Alias not configured\!/ || response_body =~ /Admin of this Helprace account needs to set up domain alias/)
        _create_hijackable_subdomain_issue "Help Race", uri, "potential"

      elsif (response_body =~ /Domain not found/ || response_body =~ /does not exist in our system/)
        _create_hijackable_subdomain_issue("Hubspot", uri, "potential")

      elsif response_body =~ /Uh oh. That page doesn\'t exist/i
        _create_hijackable_subdomain_issue("Intercom", uri, "potential") unless (uri =~ /intercom.com/ || uri =~ /intercom.io/)

      elsif response_body =~ /is not a registered InCloud YouTrack/i
        _create_hijackable_subdomain_issue "JetBrains", uri, "potential"

      elsif response_body =~ /No Site For Domain/i
        _create_hijackable_subdomain_issue "Kinsta", uri, "potential"

      elsif response_body =~ /It looks like you\'re lost/i
        _create_hijackable_subdomain_issue "Landingi", uri, "potential"

      elsif response_body =~ /It looks like you may have taken a wrong turn somewhere/i
        _create_hijackable_subdomain_issue "LaunchRock", uri, "potential"  unless (uri =~ /launchrock.com/ || uri =~ /amazonaws.com/)

      elsif response_body =~ /Unrecognized domain/i
        _create_hijackable_subdomain_issue "Mashery", uri, "potential" unless (uri =~ /mashery.com/ || uri =~ /amazonaws.com/)

      elsif (response_body =~ /ngrok\.io not found/ || response_body =~ /Tunnel \*\.ngrok\.io not found/)
        _create_hijackable_subdomain_issue "Ngrok", uri, "potential"

      elsif response_body =~ /The gods are wise, but do not know of the site which you seek\!/i
        _create_hijackable_subdomain_issue "Pantheon", uri, "potential" unless (uri =~ /pantheon.io/ || uri =~ /amazonaws.com/)

      elsif (response_body =~ /Public Report Not Activated/ || response_body =~ /This public report page has not been activated by the user/)
        _create_hijackable_subdomain_issue "Pingdom", uri, "potential"

      elsif response_body =~ /If you need immediate assistance, please contact \<a href\=\"mailto\:support\@proposify\.biz/
        _create_hijackable_subdomain_issue "Propsify", uri, "potential"

      elsif response_body =~ /Project doesnt exist... yet!/i
        _create_hijackable_subdomain_issue "Readme.io", uri, "potential" unless (uri =~ /readme.io/ || uri =~ /amazonaws.com/)

      elsif response_body =~ /unknown to Read the Docs/
        _create_hijackable_subdomain_issue "Readthedocs", uri, "potential"

      elsif response_body =~ /Sorry, this shop is currently unavailable./i
        _create_hijackable_subdomain_issue("Shopify", uri, "potential") unless (uri =~ /shopify.com/ || uri =~ /myshopify.com/)

      elsif response_body =~ /<title>Statuspage \| Hosted Status Page/i
        _create_hijackable_subdomain_issue("Statuspage", uri, "potential") unless (
          uri =~ /statuspage.com/ || uri =~ /statuspage.io/ || uri =! /amazonaws.com/)

      #elsif response_body =~ /page not found/i
      #  _create_hijackable_subdomain_issue "Strikingly", uri, "potential"

      elsif response_body =~ /We can\'t find this \<a href=\"https\:\/\/simplebooklet\.com/i
        _create_hijackable_subdomain_issue "Simplebooklet", uri, "potential"

      elsif (response_body =~ /Job Board Is Unavailable/ || response_body =~ /This job board website is either expired/ || response_body =~ /This job board website is either expired or its domain name is invalid/)
        _create_hijackable_subdomain_issue "Smartjob", uri, "potential"

      elsif response_body =~ /Domain is not configured/i
        _create_hijackable_subdomain_issue "Smartling", uri, "potential"

      elsif response_body =~ /\{\"text\"\:\"Page Not Found\"/i
        _create_hijackable_subdomain_issue "Smugmug", uri, "potential"

      elsif response_body =~ /project not found/i
        _create_hijackable_subdomain_issue "Surge.sh", uri, "potential"

      # potentially may lead to false positives, adding for now but will monitor - shpendk
      elsif response_body =~ /data\-html\-name/i
        _create_hijackable_subdomain_issue "Surveygizmo", uri, "potential"

      elsif response_body =~ /Whatever you were looking for doesn\'t currently exist at this address/i
        _create_hijackable_subdomain_issue "Tumblr", uri, "potential" unless (uri =~ /tumblr.com/ || uri =~ /yahoo.com/)

      elsif response_body =~ /Please renew your subscription/i
        _create_hijackable_subdomain_issue "Tilda", uri, "potential"

      elsif response_body =~ /Oops \- We didn\'t find your site/i
        _create_hijackable_subdomain_issue "Teamwork", uri, "potential"

      elsif response_body =~ /You may have mistyped the address or the page may have moved/i
        _create_hijackable_subdomain_issue "Thinkific", uri, "potential"

      elsif (response_body =~ /Building a brand of your own\?/ || response_body =~ /to target URL\: \<a href\=\"https\:\/\/tictail\.com/ || response_body =~ /Start selling on Tictail/)
        _create_hijackable_subdomain_issue "Tictail", uri, "potential"

      elsif response_body =~ /Non-hub domain\, The URL you\'ve accessed does not provide a hub/i
        _create_hijackable_subdomain_issue "Uberflip", uri, "potential"

      #elsif response_body =~ /page not found/i
      #  _create_hijackable_subdomain_issue "UptimeRobot", uri, "potential"
        
      # Per this issue: https://github.com/EdOverflow/can-i-take-over-xyz/issues/11
      # unbounce is only vulnerable if the pointing cname has NEVER been claimed on unbouce. As this is a rare situation, unbounce is currently disabled.
      #elsif response_body =~ /The requested URL was not found on this server\./i
      #  _create_hijackable_subdomain_issue("Unbounce", uri, "potential") unless (uri =~ /unbounce.com/)

      elsif response_body =~ /This UserVoice subdomain is currently available\!/i
        _create_hijackable_subdomain_issue "UserVoice", uri, "potential"

      elsif response_body =~ /Looks like you\'ve traveled too far into cyberspace/i
        _create_hijackable_subdomain_issue "Vend", uri, "potential"

      elsif response_body =~ /domain is already connected to a Webflow site/i
        _create_hijackable_subdomain_issue "Webflow", uri, "potential" unless (uri =~ /webflow.io/)

      elsif response_body =~ /https\:\/\/www\.wishpond\.com\/404\?campaign\=true/i
        _create_hijackable_subdomain_issue "Wishpond", uri, "potential"

      elsif response_body =~ /Do you want to register \*\.wordpress\.com/i
        _create_hijackable_subdomain_issue "Wordpress", uri, "potential" unless (uri =~ /wordpress.com/)

      elsif response_body =~ /Domain mapping upgrade for this domain not found. Please/i
        _create_hijackable_subdomain_issue "Wordpress", uri, "potential" unless (uri =~ /wordpress.com/)

      # potentially may lead to false positives, adding for now but will monitor - shpendk
      elsif response_body =~ /Company not found/i
        _create_hijackable_subdomain_issue "Worksites", uri, "potential"

      elsif (response_body =~ /Profile not found/ || response_body =~ /Hmmm\.\.\.\.something is not right/)
        _create_hijackable_subdomain_issue "Wufoo", uri, "potential"

      # disabled per https://github.com/EdOverflow/can-i-take-over-xyz
      #elsif response_body =~ /this help center no longer exists/i
      #  _create_hijackable_subdomain_issue "Zendesk", uri, "potential"

      # disabled per https://github.com/EdOverflow/can-i-take-over-xyz
      #elsif response_body =~ /This domain is successfully pointed at WP Engine, but is not configured/i
      #  _create_hijackable_subdomain_issue "WPEngine", uri, "potential"

      end
    end

  end #end run

  def _create_hijackable_subdomain_issue type, uri, status
    _create_linked_issue("subdomain_hijack",{
      type: "Subdomain Hijacking Detected (#{type})",
      detailed_description: " This uri #{uri} appears to be unclaimed on a third party host, meaning," +
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
