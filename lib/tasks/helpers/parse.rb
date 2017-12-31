module Intrigue
module Task
module Parse

  def parse_web_account_from_uri(url)
    # Handle Twitter search results
    if url =~ /https?:\/\/twitter.com\/.*$/
      account_name = url.split("/")[3]
      _create_entity("WebAccount", {
        "domain" => "twitter.com",
        "name" => account_name,
        "uri" => "#{url}",
        "type" => "full"
      })

    # Handle Facebook public profile  results
    elsif url =~ /https?:\/\/www.facebook.com\/(public|pages)\/.*$/
      account_name = url.split("/")[4]
      _create_entity("WebAccount", {
        "domain" => "facebook.com",
        "name" => account_name,
        "uri" => "#{url}",
        "type" => "public"
      })

    # Handle Facebook search results
    elsif url =~ /https?:\/\/www.facebook.com\/.*$/
      account_name = url.split("/")[3]
      _create_entity("WebAccount", {
        "domain" => "facebook.com",
        "name" => account_name,
        "uri" => "#{url}",
        "type" => "full"
      })

    # Handle LinkedIn public profiles
    elsif url =~ /^https?:\/\/www.linkedin.com\/in\/pub\/.*$/
        account_name = url.split("/")[5]
        _create_entity("WebAccount", {
          "domain" => "linkedin.com",
          "name" => account_name,
          "uri" => "#{url}",
          "type" => "public"
        })

    # Handle LinkedIn public directory search results
    elsif url =~ /^https?:\/\/www.linkedin.com\/pub\/dir\/.*$/
      account_name = "#{url.split("/")[5]} #{url.split("/")[6]}"
      _create_entity("WebAccount", {
        "domain" => "linkedin.com",
        "name" => account_name,
        "uri" => "#{url}",
        "type" => "public"
      })

    # Handle LinkedIn world-wide directory results
    elsif url =~ /^http:\/\/[\w]*.linkedin.com\/pub\/.*$/

    # Parses these URIs:
    #  - http://za.linkedin.com/pub/some-one/36/57b/514
    #  - http://uk.linkedin.com/pub/some-one/78/8b/151

      account_name = url.split("/")[4]
      _create_entity("WebAccount", {
        "domain" => "linkedin.com",
        "name" => account_name,
        "uri" => "#{url}",
        "type" => "public" })

    # Handle LinkedIn profile search results
    elsif url =~ /^https?:\/\/www.linkedin.com\/in\/.*$/
      account_name = url.split("/")[4]
      _create_entity("WebAccount", {
        "domain" => "linkedin.com",
        "name" => account_name,
        "uri" => "#{url}",
        "type" => "public" })

    # Handle Google Plus search results
    elsif url =~ /https?:\/\/plus.google.com\/.*$/
      account_name = url.split("/")[3]
      _create_entity("WebAccount", {
        "domain" => "google.com",
        "name" => account_name,
        "uri" => "#{url}",
        "type" => "full" })

    # Handle Hackerone search results
    elsif url =~ /https?:\/\/hackerone.com\/.*$/
      account_name = url.split("/")[3]
      _create_entity("WebAccount", {
        "domain" => "hackerone.com",
        "name" => account_name,
        "uri" => url,
        "type" => "full" }) unless account_name == "reports"
    end
  end




end
end
end
