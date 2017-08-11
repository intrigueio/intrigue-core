module Intrigue
module Task
module Data

  def simple_web_creds
   [
      {"username" => "admin",     "password" => "admin"},
      {"username" => "anonymous", "password" => "anonymous"},
      {"username" => "cisco",     "password" => "cisco"},
      {"username" => "demo",      "password" => "demo"},
      {"username" => "demo1",     "password" => "demo1"},
      {"username" => "guest",     "password" => "guest"},
      {"username" => "test",      "password" => "test"},
      {"username" => "test1",     "password" => "test1"},
      {"username" => "test123",   "password" => "test123"},
      {"username" => "test123!!", "password" => "test123!!"}
    ]
  end

  def hidden_entity?(entity_name, type_string=nil)
    if type_string == "IpAddress"

      return true if (
          # Skip Akamai
          entity_name =~ /^23\..*$/              ||
          entity_name =~ /^2600:1400.*$/         ||
          entity_name =~ /^2600:1409.*$/         ||

          # Skip Incapsula... lots of annoying scan results here
          entity_name =~ /107\.154\.*/           ||

          # RFC1918
          entity_name =~ /^172\.16\..*$/         ||
          entity_name =~ /^192\.168\..*$/        ||
          entity_name =~ /^10\..*$/              ||

          # localhost
          entity_name =~ /^127\..*$/             ||
          entity_name =~ /^0.0.0.0/ )
    end

    # Standard exclusions
    return true if (
        entity_name =~ /^.*1e100.net$/                     ||
        entity_name =~ /^.*2o7.net$/                       ||
        entity_name =~ /^.*akadns.net$/                    ||
        entity_name =~ /^.*akam.net$/                      ||
        entity_name =~ /^.*akamai.net$/                    ||
        entity_name =~ /^.*akamai.com$/                    ||
        entity_name =~ /^.*akamaiedge.net$/                ||
        entity_name =~ /^.*akamaihd-staging.net$/          ||
        entity_name =~ /^.*akamaihd.net$/                  ||
        entity_name =~ /^.*akamaistream.net$/              ||
        entity_name =~ /^.*akamaitechnologies.net$/        ||
        entity_name =~ /^.*akamaitechnologies.com$/        ||
        entity_name =~ /^.*akamaized-staging.net$/         ||
        entity_name =~ /^.*akamaized.net$/                 ||
        #entity_name =~ /^.*amazonaws.com$/                 ||
        entity_name =~ /^.*android.clients.google.com$/    ||
        entity_name =~ /^.*android.com$/                   ||
        entity_name =~ /^.*apache.org$/                    ||
        entity_name =~ /^.*\.arpa$/                        ||
        entity_name =~ /^.*azure-mobile.net$/              ||
        entity_name =~ /^.*azureedge-test.net$/            ||
        entity_name =~ /^.*azureedge.net$/                 ||
        entity_name =~ /^.*azurewebsites.net$/             ||
        entity_name =~ /^.*cloudapp.net$/                  ||
        entity_name =~ /^.*cloudfront.net$/                ||
        entity_name =~ /^.*drupal.org$/                    ||
        entity_name =~ /^.*edgecastcdn.net$/               ||
        entity_name =~ /^.*edgekey.net$/                   ||
        entity_name =~ /^.*edgesuite.net$/                 ||
        entity_name =~ /^.*facebook.com$/                  ||
        entity_name =~ /^.*feeds2.feedburner.com$/         ||
        entity_name =~ /^.*g.co$/                          ||
        entity_name =~ /^.*gandi.net$/                     ||
        entity_name =~ /^.*goo.gl$/                        ||
        entity_name =~ /^.*google-analytics.com$/          ||
        entity_name =~ /^.*google.ca$/                     ||
        entity_name =~ /^.*google.cl$/                     ||
        entity_name =~ /^.*google.co.in$/                  ||
        entity_name =~ /^.*google.co.jp$/                  ||
        entity_name =~ /^.*google.co.uk$/                  ||
        entity_name =~ /^.*google.com$/                    ||
        entity_name =~ /^.*google.com.ar$/                 ||
        entity_name =~ /^.*google.com.au$/                 ||
        entity_name =~ /^.*google.com.br$/                 ||
        entity_name =~ /^.*google.com.co$/                 ||
        entity_name =~ /^.*google.com.mx$/                 ||
        entity_name =~ /^.*google.com.tr$/                 ||
        entity_name =~ /^.*google.com.vn$/                 ||
        entity_name =~ /^.*google.de$/                     ||
        entity_name =~ /^.*google.es$/                     ||
        entity_name =~ /^.*google.fr$/                     ||
        entity_name =~ /^.*google.hu$/                     ||
        entity_name =~ /^.*google.it$/                     ||
        entity_name =~ /^.*google.nl$/                     ||
        entity_name =~ /^.*google.pl$/                     ||
        entity_name =~ /^.*google.pt$/                     ||
        entity_name =~ /^.*googleadapis.com$/              ||
        entity_name =~ /^.*googleapis.cn$/                 ||
        entity_name =~ /^.*googlecommerce.com$/            ||
        entity_name =~ /^.*googlehosted.com$/              ||
        entity_name =~ /^.*googlemail.com$/                ||
        entity_name =~ /^.*gstatic.cn$/                    ||
        entity_name =~ /^.*gstatic.com$/                   ||
        entity_name =~ /^.*gvt1.com$/                      ||
        entity_name =~ /^.*gvt2.com$/                      ||
        entity_name =~ /^.*herokussl.com$/                 ||
        entity_name =~ /^.*hubspot.com$/                   ||
        entity_name =~ /^.*hubspot.net$/                   ||
        entity_name =~ /^.*incapdns.net$/                  ||
        entity_name =~ /^.*instagram.com$/                 ||
        entity_name =~ /^.*localhost$/                     ||
        entity_name =~ /^.*lync.com$/                      ||
        entity_name =~ /^.*mandrillapp.com$/               ||
        entity_name =~ /^.*marketo.com$/                   ||
        entity_name =~ /^.*metric.gstatic.com$/            ||
        entity_name =~ /^.*mktoweb.com$/                   ||
        entity_name =~ /^.*microsoft.com$/                 ||
        entity_name =~ /^.*msn.com$/                       ||
        entity_name =~ /^.*oclc.org$/                      ||
        entity_name =~ /^.*office365.com$/                 ||
        entity_name =~ /^.*ogp.me$/                        ||
        entity_name =~ /^.*outlook.com$/                   ||
        entity_name =~ /^.*plus.google.com$/               ||
        entity_name =~ /^.*posterous.com$/                 ||
        entity_name =~ /^.*purl.org$/                      ||
        entity_name =~ /^.*rdfs.org$/                      ||
        entity_name =~ /^.*root-servers.net$/              ||
        entity_name =~ /^.*schema.org$/                    ||
        entity_name =~ /^.*sendgrid.net$/                  ||
        entity_name =~ /^.*secureserver.net$/              ||
        entity_name =~ /^.*squarespace.com$/               ||
        entity_name =~ /^.*statuspage.io$/                 ||
        entity_name =~ /^.*twitter.com$/                   ||
        entity_name =~ /^.*urchin.com$/                    ||
        entity_name =~ /^.*url.google.com$/                ||
        entity_name =~ /^.*v0cdn.net$/                     ||
        entity_name =~ /^.*w3.org$/                        ||
        entity_name =~ /^.*windows.net$/                   ||
        entity_name =~ /^.*windowsphone-int.net$/          ||
        entity_name =~ /^.*windowsphone.com$/              ||
        entity_name =~ /^.*www.goo.gl$/                    ||
        entity_name =~ /^.*xmlns.com$/                     ||
        entity_name =~ /^.*youtu.be$/                      ||
        entity_name =~ /^.*youtube-nocookie.com$/          ||
        entity_name =~ /^.*youtube.com$/                   ||
        entity_name =~ /^.*youtubeeducation.com$/          ||
        entity_name =~ /^.*ytimg.com$/                     ||
        entity_name =~ /^.*zendesk.com$/                   ||
        entity_name =~ /^.*zepheira.com$/                  ||
        entity_name =~ /^.*1e100.com$/ )
  end



end
end
end
