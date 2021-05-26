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

      if response_body.match(/The specified bucket does not exist/i) && !(uri =~ /amazonaws.com/ || uri =~ /aws.amazon.com/ || uri =~ /googleapis.com/)
        _create_hijackable_subdomain_issue "AWS S3", uri, "potential"

      #elsif response_body.match /If you are an Acquia Cloud customer and expect to see your site/i
      #  _create_hijackable_subdomain_issue "Acquia", uri, "potential"

      #elsif response_body.match /The site you are looking for could not be found./i
      #  _create_hijackable_subdomain_issue "Acquia", uri, "potential"

      #elsif response_body.match /Oops\.<\/h2><p class=\"text-muted text-tight\">The page you\'re looking for doesn/i
      #  _create_hijackable_subdomain_issue "Aftership", uri, "potential"

      elsif response_body.match /Sorry, this page is no longer available./i
        _create_hijackable_subdomain_issue "AgileCRM", uri, "potential"

      #elsif response_body.match /There is no portal here \.\.\. sending you back to Aha\!/i
      #  _create_hijackable_subdomain_issue "Aha.io", uri, "potential"

      elsif response_body.match /Ошибка 402. Сервис Айри.рф не оплачен/i
        _create_hijackable_subdomain_issue "Airee", uri, "potential"

      elsif response_body.match /If this is your website and you've just created it, try refreshing in a minute/i
        _create_hijackable_subdomain_issue "Anima", uri, "potential"

      #elsif response_body.match /\<h1\>Oops\! We couldn\&\#8217\;t find that page\.<\/h1>/i
      #  _create_hijackable_subdomain_issue "BigCartel", uri, "potential"

      elsif response_body.match /Repository not found/i
        _create_hijackable_subdomain_issue "Bitbucket", uri, "potential"

      #elsif response_body.match /<p class=\"bc-gallery-error-code\">Error Code: 404<\/p>/i
      #  _create_hijackable_subdomain_issue "Brightcove", uri, "potential"

      elsif response_body.match /<strong>Trying to access your account\?<\/strong>/i
        unless (uri =~ /createsend.com/ || uri =~ /amazonaws.com/)
          _create_hijackable_subdomain_issue "CampaignMonitor", uri, "potential"
        end

      #elsif response_body.match(/There is no such company. Did you enter the right URL\?/i) ||
      #        response_body.match(/Company Not Found/i)
      #  _create_hijackable_subdomain_issue "Canny", uri, "potential"

      elsif response_body.match(/If you\'re moving your domain away from Cargo you/i) ||
        (response_body.match(/<title>404 Not Found<\/title>/) && response_body.match(/auth.cargo.site/))
        _create_hijackable_subdomain_issue "CargoCollective", uri, "potential"

      #elsif response_body.match /404 Not Found/i # TODO... check uri && file against alias groups?
      #  _create_hijackable_subdomain_issue "CargoCollective | Fly.io | Netlify", uri, "potential"

      
      elsif response_body.match /Fastly error: unknown domain/i
        _create_hijackable_subdomain_issue "Fastly", uri, "potential" unless uri =~ /fastly.com/

      #elsif response_body.match /The feed has not been found\./i
      #  _create_hijackable_subdomain_issue "Feedpress", uri, "potential" unless uri =~ /feedpress.com.com/

      #elsif response_body.match /\<title\>Flywheel - Unknown Domain/i
      #  _create_hijackable_subdomain_issue "Flywheel", uri, "potential" unless uri =~ /flywheel.com/ || uri =~ /flywheel.io/

      # unable to verify 2020-07-21
      #elsif response_body.match /Oops… looks like you got lost/i
      #  _create_hijackable_subdomain_issue "Frontify", uri, "potential"

      elsif response_body.match /404: This page could not be found./i
        _create_hijackable_subdomain_issue "Gemfury", uri, "potential"

      #elsif response_body.match /With GetResponse Landing Pages, lead generation has never been easier/i
      #  _create_hijackable_subdomain_issue "GetRespone", uri, "potential"

      elsif response_body.match /The thing you were looking for is no longer here/i
        _create_hijackable_subdomain_issue "Ghost", uri, "potential"

      elsif response_body.match /There isn\'t a Github Pages site here/i
        _create_hijackable_subdomain_issue("Github", uri, "potential") unless (uri =~ /github.com/ || uri =~ /github.io/)

      # https://hackerone.com/reports/1034023
      # No longer possible, commenting...
      # https://support.freshdesk.com/support/solutions/articles/37590-using-a-vanity-support-url-and-pointing-the-cname
      #elsif response_body.match(/There is no helpdesk here/i) && response_body.match(/Maybe this is still fresh/i)
      #  _create_hijackable_subdomain_issue("Freshdesk", uri, "potential") unless uri =~ /freshdesk.com/

      #elsif response_body.match /404 Blog is not found/i
      #  _create_hijackable_subdomain_issue "", uri, "potential"

      elsif response_body.match /No such app/i

        if !(uri =~ /heroku.com/ || uri =~ /herokussl.com/ || uri =~ /herokudns.com/ ||
              uri =~ /herokuapp.com/ || uri =~ /amazonaws.com/)
          _create_hijackable_subdomain_issue "Heroku", uri, "potential"
        end

      elsif response_body.match /No settings were found for this company:/i
        _create_hijackable_subdomain_issue "Help Scout", uri, "potential" unless (uri =~ /helpscoutdocs.com/ || uri =~ /amazonaws.com/)

      elsif response_body.match /We could not find what you're looking for\./i
        _create_hijackable_subdomain_issue "Help Juice", uri, "potential"

      #elsif response_body.match(/Alias not configured\!/) || response_body.match(/Admin of this Helprace account needs to set up domain alias/)
      #  _create_hijackable_subdomain_issue "Help Race", uri, "potential"


      #elsif response_body.match(/Domain not found/) || response_body.match(/does not exist in our system/)
        # possibly a hubspot entry. Resolve and check CNAME
      #  resolved_name = resolve_name hostname, [Resolv::DNS::Resource::IN::CNAME]
      #  if "#{resolved_name}" =~ /.*\.hubspot\.net$/
          # target resolves to a subdomain of .hubspot.net. This is likely a valid finding.
      #    _create_hijackable_subdomain_issue("Hubspot", uri, "potential")
      #  end

      elsif response_body.match /Uh oh. That page doesn\'t exist/i
        _create_hijackable_subdomain_issue("Intercom", uri, "potential") unless (uri =~ /intercom.com/ || uri =~ /intercom.io/)

      elsif response_body.match /is not a registered InCloud YouTrack/i
        _create_hijackable_subdomain_issue "JetBrains", uri, "potential"

      elsif response_body.match /No Site For Domain/i
        _create_hijackable_subdomain_issue "Kinsta", uri, "potential"

      elsif response_body.match /It looks like you\'re lost/i
        _create_hijackable_subdomain_issue "Landingi", uri, "potential"

      elsif response_body.match /It looks like you may have taken a wrong turn somewhere/i
        _create_hijackable_subdomain_issue "LaunchRock", uri, "potential"  unless (uri =~ /launchrock.com/ || uri =~ /amazonaws.com/)

      elsif response_body.match /Unrecognized domain/i
        _create_hijackable_subdomain_issue "Mashery", uri, "potential" unless (uri =~ /mashery.com/ || uri =~ /amazonaws.com/)

      # https://hackerone.com/reports/1034023
      elsif response_body.match /Oops\! We couldn\’t find that page\. Sorry about that\./i
        _create_hijackable_subdomain_issue "Medium", uri, "potential" unless uri =~ /medium.com/

      elsif response_body.match(/ngrok\.io not found/) || response_body.match(/Tunnel \*\.ngrok\.io not found/)
        _create_hijackable_subdomain_issue "Ngrok", uri, "potential"

      elsif response_body.match /404 error unknown site\!/i
        _create_hijackable_subdomain_issue "Pantheon", uri, "potential" unless (uri =~ /pantheon.io/ || uri =~ /amazonaws.com/)

      elsif response_body.match(/Sorry, couldn\'t find the status page/) 
        _create_hijackable_subdomain_issue "Pingdom", uri, "potential"

      #elsif response_body.match /If you need immediate assistance, please contact \<a href\=\"mailto\:support\@proposify\.biz/
      #  _create_hijackable_subdomain_issue "Propsify", uri, "potential"

      elsif response_body.match /Project doesnt exist\.\.\. yet\!/i
        _create_hijackable_subdomain_issue "Readme.io", uri, "potential" unless (uri =~ /readme.io/ || uri =~ /amazonaws.com/)

      #elsif response_body.match /unknown to Read the Docs/
      #  _create_hijackable_subdomain_issue "Readthedocs", uri, "potential"

      elsif response_body.match /Sorry, this shop is currently unavailable./i
        _create_hijackable_subdomain_issue("Shopify", uri, "potential") unless (uri =~ /shopify.com/ || uri =~ /myshopify.com/)

      #elsif response_body.match /<title>Statuspage \| Hosted Status Page/i
      #  _create_hijackable_subdomain_issue("Statuspage", uri, "potential") unless (
      #    uri =~ /statuspage.com/ || uri =~ /statuspage.io/ || uri =! /amazonaws.com/)

      elsif response_body.match /Page not found \- Strikingly/i && uri =~ /strikinglydns.com/
        _create_hijackable_subdomain_issue "Strikingly", uri, "potential"

      #elsif response_body.match /We can\'t find this \<a href=\"https\:\/\/simplebooklet\.com/i
      #  _create_hijackable_subdomain_issue "Simplebooklet", uri, "potential"

      elsif response_body.match(/Job Board Is Unavailable/) ||
              response_body.match(/This job board website is either expired/) ||
              response_body.match(/This job board website is either expired or its domain name is invalid/)
        _create_hijackable_subdomain_issue "Smartjob", uri, "potential"

      elsif response_body.match /Domain is not configured/i
        _create_hijackable_subdomain_issue "Smartling", uri, "potential"

      #elsif response_body.match /\{\"text\"\:\"Page Not Found\"/i
      #  _create_hijackable_subdomain_issue "Smugmug", uri, "potential"

      elsif response_body.match /project not found/i
        _create_hijackable_subdomain_issue "Surge.sh", uri, "potential"

      # potentially may lead to false positives, adding for now but will monitor - shpendk
      #elsif response_body.match /data\-html\-name/i
      #  _create_hijackable_subdomain_issue "Surveygizmo", uri, "potential"

      elsif response_body.match /Whatever you were looking for doesn\'t currently exist at this address/i
        _create_hijackable_subdomain_issue "Tumblr", uri, "potential" unless (uri =~ /tumblr.com/ || uri =~ /yahoo.com/)

      elsif response_body.match /Please renew your subscription/i
        _create_hijackable_subdomain_issue "Tilda", uri, "potential"

      #elsif response_body.match /Oops \- We didn\'t find your site/i
      #  _create_hijackable_subdomain_issue "Teamwork", uri, "potential"

      #elsif response_body.match(/Building a brand of your own\?/) ||
      #        response_body.match(/to target URL\: \<a href\=\"https\:\/\/tictail\.com/) ||
      #        response_body.match(/Start selling on Tictail/)
      #  _create_hijackable_subdomain_issue "Tictail", uri, "potential"

      elsif response_body.match /Non-hub domain\, The URL you\'ve accessed does not provide a hub/i
        _create_hijackable_subdomain_issue "Uberflip", uri, "potential"


      # Per this issue: https://github.com/EdOverflow/can-i-take-over-xyz/issues/11
      # unbounce is only vulnerable if the pointing cname has NEVER been claimed on unbouce. As this is a rare situation, unbounce is currently disabled.
      #elsif response_body.match /The requested URL was not found on this server\./i
      #  _create_hijackable_subdomain_issue("Unbounce", uri, "potential") unless (uri =~ /unbounce.com/)

      elsif response_body.match /This UserVoice subdomain is currently available\!/i
        _create_hijackable_subdomain_issue "UserVoice", uri, "potential"

      #elsif response_body.match /Looks like you\'ve traveled too far into cyberspace/i
      #  _create_hijackable_subdomain_issue "Vend", uri, "potential"

      #elsif response_body.match /The deployment could not be found on Vercel\./i
      #  _create_hijackable_subdomain_issue "Vercel", uri, "potential" unless uri =~ /vercel-dns.com/

      elsif response_body.match /The page you are looking for doesn\'t exist or has been moved\./i
        _create_hijackable_subdomain_issue "Webflow", uri, "potential" unless (uri =~ /webflow.io/)

      #elsif response_body.match /https\:\/\/www\.wishpond\.com\/404\?campaign\=true/i
      #  _create_hijackable_subdomain_issue "Wishpond", uri, "potential"

      elsif response_body.match /Do you want to register \*\.wordpress\.com/i
        _create_hijackable_subdomain_issue "Wordpress", uri, "potential" unless (uri =~ /wordpress.com/)

      #elsif response_body.match /Domain mapping upgrade for this domain not found. Please/i
      #  _create_hijackable_subdomain_issue "Wordpress", uri, "potential" unless (uri =~ /wordpress.com/)

      # potentially may lead to false positives, adding for now but will monitor - shpendk
      elsif response_body.match /Hello\! Sorry, but the website you/i
        _create_hijackable_subdomain_issue "Worksites", uri, "potential"

      #elsif response_body.match(/Profile not found/) ||
      #        response_body.match(/Hmmm\.\.\.\.something is not right/)
      #  _create_hijackable_subdomain_issue "Wufoo", uri, "potential"

      # disabled per https://github.com/EdOverflow/can-i-take-over-xyz
      #elsif response_body.match /this help center no longer exists/i
      #  _create_hijackable_subdomain_issue "Zendesk", uri, "potential"

      # disabled per https://github.com/EdOverflow/can-i-take-over-xyz
      #elsif response_body.match /This domain is successfully pointed at WP Engine, but is not configured/i
      #  _create_hijackable_subdomain_issue "WPEngine", uri, "potential"

      elsif response_body.match /Trying to access your account\?/i
        _create_hijackable_subdomain_issue "CampaignMonitor", uri, "potential"
        
      elsif response_body.match /404 Blog is not found/i
        _create_hijackable_subdomain_issue "HatenaBlog", uri, "potential"  

      elsif response_body.match /This job board website is either expired or its domain name is invalid\./i
        _create_hijackable_subdomain_issue "SmartJobBoard", uri, "potential"

      # TODO ... digital ocean https://github.com/EdOverflow/can-i-take-over-xyz
      # "Domain uses DO name serves with no records in DO."

      # TODO Discourse, looks like it's also can be checked by the record only

      # TODO Azure, nxdomain response on the subdomain is required

      # TODO UptimeRobot, CNAME  to stats.uptimerobot.com is required, as "page not found" in body is too generic
      

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
