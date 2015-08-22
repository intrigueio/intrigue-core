module Intrigue
class UriGatherTechnologyTask  < BaseTask

  include Intrigue::Task::Web

  def metadata
    {
      :name => "uri_gather_technology",
      :pretty_name => "URI Gather Technology",
      :authors => ["jcran"],
      :description => "This task determines platform and technologies of the target.",
      :references => [],
      :allowed_types => ["Uri"],
      :example_entities => [{"type" => "Uri", "attributes" => {:name => "http://www.intrigue.io"}}],
      :allowed_options => [],
      :created_types => ["SoftwarePackage"]
    }
  end

  def run
    super

    uri = _get_entity_attribute "name"

    @task_log.log "Connecting to #{uri} for #{@entity}"

    # Gather the page body
    contents = http_get_body(uri)

    target_strings = [

      ###
      ### Security Seals
      ###
      # http://baymard.com/blog/site-seal-trust
      # https://vagosec.org/2014/11/clubbing-seals/
      #
      { :regex => /Norton Secured, Powered by Symantec/,
        :finding_name => "Norton Security Seal"},
      { :regex => /PathDefender/,
        :finding_name => "McAfee Pathdefender Security Seal"},

      ### Marketing / Tracking
      {:regex => /urchin.js/, :finding_name => "Google Analytics"},
      {:regex => /optimizely/, :finding_name => "Optimizely"},
      {:regex => /trackalyze/, :finding_name => "Trackalyze"},
      {:regex => /doubleclick.net|googleadservices/,
        :finding_name => "Google Ads"},
      {:regex => /munchkin.js/, :finding_name => "Marketo"},
      {:regex => /Olark live chat software/, :finding_name => "Olark"},

      ###
      ### TODO - is this matching enough to get context? Use lookarounds.
      ###

      ### External accounts
      {:regex => /http:\/\/www.twitter.com.*?/,
        :finding_name => "Twitter Account"},
      {:regex => /http:\/\/www.facebook.com.*?/,
        :finding_name => "Facebook Account"},

      ### Technologies
      #{:regex => /javascript/, :finding => "Javascript"},
      {:regex => /jquery.js/, :finding_name => "JQuery"},
      {:regex => /bootstrap.css/, :finding_name => "Twitter Bootstrap"},

      ### Platform
      {:regex => /[W|w]ordpress/, :finding_name => "Wordpress"},
      {:regex => /[D|d]rupal/, :finding_name => "Drupal"},

      ### Provider
      {:regex => /Content Delivery Network via Amazon Web Services/,
        :finding_name => "Amazon Cloudfront"},

      ### Wordpress Plugins
      { :regex => /wp-content\/plugins\/.*?\//,
        :finding_name => "Wordpress Plugin" },
      { :regex => /xmlrpc.php/, :finding_name => "Wordpress API"},
      #{:regex => /Yoast WordPress SEO plugin/, :finding_name => "Yoast Wordress SEO Plugin"},
      #{:regex => /PowerPressPlayer/, :finding_name => "Powerpress Wordpress Plugin"},
    ]

    # Iterate through the target strings
    target_strings.each do |target|
      matches = contents.scan(target[:regex]) #.map{Regexp.last_match}

      # Iterate through all matches
      matches.each do |match|
       _create_entity("SoftwarePackage",
        { "name" => "#{target[:finding_name]}",
          "uri" => "#{uri}",
          "content" => "Found #{match} on #{uri}" })
      end if matches
    end
    # End interation through the target strings

  end

end
end
