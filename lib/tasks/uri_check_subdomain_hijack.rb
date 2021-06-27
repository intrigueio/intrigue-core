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

    # get our response
    response_body = http_get_body(uri)

    # if we are hosted on this, we won't be able to get a cookie, skip'm.
    generic_skip_url_patterns = [
      /amazonaws.com/,
      /aws.amazon.com/,
      /googleapis.com/
    ]

    # TODO ... digital ocean https://github.com/EdOverflow/can-i-take-over-xyz
    # "Domain uses DO name serves with no records in DO."
    # TODO Discourse, looks like it's also can be checked by the record only
    # TODO Azure, nxdomain response on the subdomain is required

    to_check = [
      {
        match_type: :body,
        source: "AWS S3",
        patterns: [/The specified bucket does not exist/i],
        confirmed: false,
        skip_url_patterns: []
      },
      {
        match_type: :body,
        source: "AgileCRM",
        patterns: [/Sorry, this page is no longer available./i],
        confirmed: false,
        skip_url_patterns: []
      },
      {
        match_type: :body,
        source: "Atree",
        patterns: [/Ошибка 402. Сервис Айри.рф не оплачен/i],
        confirmed: false,
        skip_url_patterns: []
      },
      {
        match_type: :body,
        source: "Anima",
        patterns: [/If this is your website and you've just created it, try refreshing in a minute/i],
        confirmed: false,
        skip_url_patterns: []
      },
      {
        match_type: :body,
        source: "Bitbucket",
        patterns: [/Repository not found/i],
        confirmed: false,
        skip_url_patterns: []
      },
      {
        match_type: :body,
        source: "CampaignMonitor",
        patterns: [/Trying to access your account\?/i],
        confirmed: false,
        skip_url_patterns: [/createsend.com/]
      },
      {
        match_type: :body,
        source: "CargoCollective",
        patterns: [/If you\'re moving your domain away from Cargo you/i],
        confirmed: false,
        skip_url_patterns: []
      },
      {
        match_type: :body,
        source: "CargoCollective",
        patterns: [/<title>404 Not Found<\/title>/, /auth.cargo.site/] ,
        confirmed: false,
        skip_url_patterns: []
      },
      {
        match_type: :body,
        source: "Fastly",
        patterns: [/Fastly error: unknown domain/i] ,
        confirmed: false,
        skip_url_patterns: [/fastly.com/]
      },
      {
        match_type: :body,
        source: "Gemfury",
        patterns: [/404: This page could not be found./i] ,
        confirmed: false,
        skip_url_patterns: []
      },
      {
        match_type: :body,
        source: "Ghost",
        patterns: [/The thing you were looking for is no longer here/i] ,
        confirmed: false,
        skip_url_patterns: []
      },
      {
        match_type: :body,
        source: "Github",
        patterns: [/There isn\'t a Github Pages site here/i] ,
        confirmed: false,
        skip_url_patterns: [/github.com/,/github.io/]
      },
      {
        match_type: :body,
        source: "HatenaBlog",
        patterns: [/404 Blog is not found/i] ,
        confirmed: false,
        skip_url_patterns: []
      },
      {
        match_type: :body,
        source: "Heroku",
        patterns: [/No such app/i] ,
        confirmed: false,
        skip_url_patterns: [/heroku.com/, /herokussl.com/, /herokudns.com/, /herokuapp.com/]
      },
      {
        match_type: :body,
        source: "Help Scout",
        patterns: [/No settings were found for this company:/i] ,
        confirmed: false,
        skip_url_patterns: [/helpscoutdocs.com/]
      },
      {
        match_type: :body,
        source: "Help Juice",
        patterns: [/We could not find what you're looking for\./i] ,
        confirmed: false,
        skip_url_patterns: []
      },
      {
        match_type: :body,
        source: "Intercom",
        patterns: [/Uh oh. That page doesn\'t exist/i] ,
        confirmed: false,
        skip_url_patterns: [/intercom.com/, /intercom.io/]
      },
      {
        match_type: :body,
        source: "JetBrains",
        patterns: [/is not a registered InCloud YouTrack/i] ,
        confirmed: false,
        skip_url_patterns: []
      },
      {
        match_type: :body,
        source: "Kinsta",
        patterns: [/No Site For Domain/i] ,
        confirmed: false,
        skip_url_patterns: []
      },
      {
        match_type: :body,
        source: "Landingi",
        patterns: [/It looks like you\'re lost/i] ,
        confirmed: false,
        skip_url_patterns: []
      },
      {
        match_type: :body,
        source: "LaunchRock",
        patterns: [/It looks like you may have taken a wrong turn somewhere/i] ,
        confirmed: false,
        skip_url_patterns: [/launchrock.com/]
      },
      {
        match_type: :body,
        source: "Mashery",
        patterns: [/Unrecognized domain/i],
        confirmed: false,
        skip_url_patterns: [/mashery.com/]
      },
      {
        match_type: :body,
        source: "Medium",
        patterns: [/Oops\! We couldn\’t find that page\. Sorry about that\./i] ,
        confirmed: false,
        skip_url_patterns: [/medium.com/]
      },
      {
        match_type: :body,
        source: "Ngrok",
        patterns: [/ngrok\.io not found/] ,
        confirmed: false,
        skip_url_patterns: []
      },
      {
        match_type: :body,
        source: "Ngrok",
        patterns: [/Tunnel \*\.ngrok\.io not found/] ,
        confirmed: false,
        skip_url_patterns: []
      },
      {
        match_type: :body,
        source: "Pantheon",
        patterns: [/404 error unknown site\!/i] ,
        confirmed: false,
        skip_url_patterns: [/pantheon.io/]
      },
      {
        match_type: :body,
        source: "Pingdom",
        patterns: [/Sorry, couldn\'t find the status page/] ,
        confirmed: false,
        skip_url_patterns: []
      },
      {
        match_type: :body,
        source: "Readme.io",
        patterns: [/Project doesnt exist\.\.\. yet\!/i] ,
        confirmed: false,
        skip_url_patterns: [/readme.io/]
      },
      {
        match_type: :body,
        source: "Shopify",
        patterns: [/Sorry, this shop is currently unavailable./i] ,
        confirmed: false,
        skip_url_patterns: []
      },
      {
        match_type: :body,
        source: "Strikingly",
        patterns: [/Page not found \- Strikingly/i] ,
        confirmed: false,
        skip_url_patterns: [/strikinglydns.com/]
      },
      {
        match_type: :body,
        source: "SmartJobBoard",
        patterns: [/This job board website is either expired/] ,
        confirmed: false,
        skip_url_patterns: []
      },
      {
        match_type: :body,
        source: "Smartling",
        patterns: [/Domain is not configured/i] ,
        confirmed: false,
        skip_url_patterns: []
      },
      {
        match_type: :body,
        source: "Surge.sh",
        patterns: [/project not found/i] ,
        confirmed: false,
        skip_url_patterns: []
      },
      {
        match_type: :body,
        source: "Tumblr",
        patterns: [/Whatever you were looking for doesn\'t currently exist at this address/i] ,
        confirmed: false,
        skip_url_patterns: []
      },
      {
        match_type: :body,
        source: "Tilda",
        patterns: [/Please renew your subscription/i] ,
        confirmed: false,
        skip_url_patterns: []
      },
      {
        match_type: :body,
        source: "Uberflip",
        patterns: [/Non-hub domain\, The URL you\'ve accessed does not provide a hub/i] ,
        confirmed: false,
        skip_url_patterns: []
      },
      {
        match_type: :body,
        source: "UptimeRobot",
        patterns: [/The content you are looking for seems to not exist./] ,
        confirmed: false,
        skip_url_patterns: [/uptimerobot.com/]
      },
      {
        match_type: :body,
        source: "UserVoice",
        patterns: [/This UserVoice subdomain is currently available\!/i] ,
        confirmed: false,
        skip_url_patterns: []
      },
      {
        match_type: :body,
        source: "Webflow",
        patterns: [/The page you are looking for doesn\'t exist or has been moved\./i] ,
        confirmed: false,
        skip_url_patterns: [/webflow.io/]
      },
      {
        match_type: :body,
        source: "Wordpress",
        patterns: [/Do you want to register \*\.wordpress\.com/i] ,
        confirmed: false,
        skip_url_patterns: [/wordpress.com/]
      },
      {
        match_type: :body,
        source: "Worksites",
        patterns: [/Hello\! Sorry, but the website you/i] ,
        confirmed: false,
        skip_url_patterns: []
      }
    ]

    # keep track of a positive match with this var
    valid_match = nil

    # iterate through all checks
    to_check.each do |check|

      _log "Checking for takeover on #{check[:source]}"

      match_type = check[:match_type]

      # First check the pattern
      if match_type == :body
        # check all matches, remove nils (see why below)
        matches = check[:patterns].map{ |p| response_body.match(p) }.compact
      else
        _log_error "Unknown match type: #{match_type}"
      end

      # if all matches are made, we'll have the same count
      if matches.count == check[:patterns].count
        valid_match = check
      end

      # Then drop out anything that's got a skip-url
      (generic_skip_url_patterns + check[:skip_url_patterns]).each do |s|
        if uri =~/#{s}/
          valid_match = nil
        end
      end

      # break out if this iteration produced a valid match
      break if valid_match

    end

    # handle a match
    if valid_match
      # out has been set with the last valid match
      confirmed_string = valid_match[:confirmed] ? 'confirmed' : 'potential'
      _create_hijackable_subdomain_issue valid_match[:source], uri, confirmed_string, valid_match
    end

  end #end run

  def _create_hijackable_subdomain_issue type, uri, status, regex
    _create_linked_issue("subdomain_hijack",{
      type: "Subdomain Hijacking Detected (#{type})",
      details: {
        uri: uri,
        type: type
      },
      proof: "Matched pattern: #{regex}"
    })
  end


end
end
end
