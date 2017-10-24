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
        entity_name =~ /^.*1e100.net(:[0-9]*)?$/                     ||
        entity_name =~ /^.*2o7.net(:[0-9]*)?$/                       ||
        entity_name =~ /^.*akadns.net(:[0-9]*)?$/                    ||
        entity_name =~ /^.*akam.net(:[0-9]*)?$/                      ||
        entity_name =~ /^.*akamai.net(:[0-9]*)?$/                    ||
        entity_name =~ /^.*akamai.com(:[0-9]*)?$/                    ||
        entity_name =~ /^.*akamaiedge.net(:[0-9]*)?$/                ||
        entity_name =~ /^.*akamaihd-staging.net(:[0-9]*)?$/          ||
        entity_name =~ /^.*akamaihd.net(:[0-9]*)?$/                  ||
        entity_name =~ /^.*akamaistream.net(:[0-9]*)?$/              ||
        entity_name =~ /^.*akamaitechnologies.net(:[0-9]*)?$/        ||
        entity_name =~ /^.*akamaitechnologies.com(:[0-9]*)?$/        ||
        entity_name =~ /^.*akamaized-staging.net(:[0-9]*)?$/         ||
        entity_name =~ /^.*akamaized.net(:[0-9]*)?$/                 ||
        entity_name =~ /^.*amazonaws.com(:[0-9]*)?$/                 ||
        entity_name =~ /^.*android.clients.google.com(:[0-9]*)?$/    ||
        entity_name =~ /^.*android.com(:[0-9]*)?$/                   ||
        entity_name =~ /^.*apache.org(:[0-9]*)?$/                    ||
        entity_name =~ /^.*\.arpa(:[0-9]*)?$/                        ||
        entity_name =~ /^.*azure-mobile.net(:[0-9]*)?$/              ||
        entity_name =~ /^.*azureedge-test.net(:[0-9]*)?$/            ||
        entity_name =~ /^.*azureedge.net(:[0-9]*)?$/                 ||
        entity_name =~ /^.*azurewebsites.net(:[0-9]*)?$/             ||
        entity_name =~ /^.*bronto.com(:[0-9]*)?$/                    ||
        entity_name =~ /^.*bydiscourse.com(:[0-9]*)?$/               ||
        entity_name =~ /^.*chtah.com(:[0-9]*)?$/                     ||
        entity_name =~ /^.*cheetahmail.com(:[0-9]*)?$/               ||
        entity_name =~ /^.*cloudapp.net(:[0-9]*)?$/                  ||
        entity_name =~ /^.*cloudfront.net(:[0-9]*)?$/                ||
        entity_name =~ /^.*decipherinc.com(:[0-9]*)?$/               ||
        entity_name =~ /^.*discourse.org(:[0-9]*)?$/                 ||
        entity_name =~ /^.*drupal.org(:[0-9]*)?$/                    ||
        entity_name =~ /^.*edgecastcdn.net(:[0-9]*)?$/               ||
        entity_name =~ /^.*edgekey.net(:[0-9]*)?$/                   ||
        entity_name =~ /^.*edgesuite.net(:[0-9]*)?$/                 ||
        entity_name =~ /^.*exacttarget.com(:[0-9]*)?$/               ||
        entity_name =~ /^.*facebook.com(:[0-9]*)?$/                  ||
        entity_name =~ /^.*feeds2.feedburner.com(:[0-9]*)?$/         ||
        entity_name =~ /^.*g.co(:[0-9]*)?$/                          ||
        entity_name =~ /^.*gandi.net(:[0-9]*)?$/                     ||
        entity_name =~ /^.*goo.gl(:[0-9]*)?$/                        ||
        entity_name =~ /^.*google-analytics.com(:[0-9]*)?$/          ||
        entity_name =~ /^.*google.ca(:[0-9]*)?$/                     ||
        entity_name =~ /^.*google.cl(:[0-9]*)?$/                     ||
        entity_name =~ /^.*google.co.in(:[0-9]*)?$/                  ||
        entity_name =~ /^.*google.co.jp(:[0-9]*)?$/                  ||
        entity_name =~ /^.*google.co.uk(:[0-9]*)?$/                  ||
        entity_name =~ /^.*google.com(:[0-9]*)?$/                    ||
        entity_name =~ /^.*google.com.ar(:[0-9]*)?$/                 ||
        entity_name =~ /^.*google.com.au(:[0-9]*)?$/                 ||
        entity_name =~ /^.*google.com.br(:[0-9]*)?$/                 ||
        entity_name =~ /^.*google.com.co(:[0-9]*)?$/                 ||
        entity_name =~ /^.*google.com.mx(:[0-9]*)?$/                 ||
        entity_name =~ /^.*google.com.tr(:[0-9]*)?$/                 ||
        entity_name =~ /^.*google.com.vn(:[0-9]*)?$/                 ||
        entity_name =~ /^.*google.de(:[0-9]*)?$/                     ||
        entity_name =~ /^.*google.es(:[0-9]*)?$/                     ||
        entity_name =~ /^.*google.fr(:[0-9]*)?$/                     ||
        entity_name =~ /^.*google.hu(:[0-9]*)?$/                     ||
        entity_name =~ /^.*google.it(:[0-9]*)?$/                     ||
        entity_name =~ /^.*google.nl(:[0-9]*)?$/                     ||
        entity_name =~ /^.*google.pl(:[0-9]*)?$/                     ||
        entity_name =~ /^.*google.pt(:[0-9]*)?$/                     ||
        entity_name =~ /^.*googleadapis.com(:[0-9]*)?$/              ||
        entity_name =~ /^.*googleapis.cn(:[0-9]*)?$/                 ||
        entity_name =~ /^.*googlecommerce.com(:[0-9]*)?$/            ||
        entity_name =~ /^.*googlehosted.com(:[0-9]*)?$/              ||
        entity_name =~ /^.*googlemail.com(:[0-9]*)?$/                ||
        entity_name =~ /^.*gridserver.com(:[0-9]*)?$/                ||
        entity_name =~ /^.*gstatic.cn(:[0-9]*)?$/                    ||
        entity_name =~ /^.*gstatic.com(:[0-9]*)?$/                   ||
        entity_name =~ /^.*gvt1.com(:[0-9]*)?$/                      ||
        entity_name =~ /^.*gvt2.com(:[0-9]*)?$/                      ||
        entity_name =~ /^.*herokussl.com(:[0-9]*)?$/                 ||
        entity_name =~ /^.*hostgator.com(:[0-9]*)?$/                 ||
        entity_name =~ /^.*hubspot.com(:[0-9]*)?$/                   ||
        entity_name =~ /^.*hubspot.net(:[0-9]*)?$/                   ||
        entity_name =~ /^.*incapdns.net(:[0-9]*)?$/                  ||
        entity_name =~ /^.*instagram.com(:[0-9]*)?$/                 ||
        entity_name =~ /^.*jobing.com(:[0-9]*)?$/                    ||
        entity_name =~ /^.*localhost(:[0-9]*)?$/                     ||
        entity_name =~ /^.*lync.com(:[0-9]*)?$/                      ||
        entity_name =~ /^.*mailgun.org(:[0-9]*)?$/                   ||
        entity_name =~ /^.*mandrillapp.com(:[0-9]*)?$/               ||
        entity_name =~ /^.*marketo.com(:[0-9]*)?$/                   ||
        entity_name =~ /^.*metric.gstatic.com(:[0-9]*)?$/            ||
        entity_name =~ /^.*mktoweb.com(:[0-9]*)?$/                   ||
        entity_name =~ /^.*microsoft.com(:[0-9]*)?$/                 ||
        entity_name =~ /^.*mtsvc.net(:[0-9]*)?$/                     ||
        entity_name =~ /^.*msn.com(:[0-9]*)?$/                       ||
        entity_name =~ /^.*oclc.org(:[0-9]*)?$/                      ||
        entity_name =~ /^.*office365.com(:[0-9]*)?$/                 ||
        entity_name =~ /^.*ogp.me(:[0-9]*)?$/                        ||
        entity_name =~ /^.*outlook.com(:[0-9]*)?$/                   ||
        entity_name =~ /^.*plus.google.com(:[0-9]*)?$/               ||
        entity_name =~ /^.*posterous.com(:[0-9]*)?$/                 ||
        entity_name =~ /^.*purl.org(:[0-9]*)?$/                      ||
        entity_name =~ /^.*rdfs.org(:[0-9]*)?$/                      ||
        entity_name =~ /^.*root-servers.net(:[0-9]*)?$/              ||
        entity_name =~ /^.*schema.org(:[0-9]*)?$/                    ||
        entity_name =~ /^.*sendgrid.net(:[0-9]*)?$/                  ||
        entity_name =~ /^.*secureserver.net(:[0-9]*)?$/              ||
        entity_name =~ /^.*siftscience.com(:[0-9]*)?$/               ||
        entity_name =~ /^.*squarespace.com(:[0-9]*)?$/               ||
        entity_name =~ /^.*statuspage.io(:[0-9]*)?$/                 ||
        entity_name =~ /^.*twitter.com(:[0-9]*)?$/                   ||
        entity_name =~ /^.*uberflip.com(:[0-9]*)?$/                  ||
        entity_name =~ /^.*urchin.com(:[0-9]*)?$/                    ||
        entity_name =~ /^.*url.google.com(:[0-9]*)?$/                ||
        entity_name =~ /^.*v0cdn.net(:[0-9]*)?$/                     ||
        entity_name =~ /^.*w3.org(:[0-9]*)?$/                        ||
        entity_name =~ /^.*windows.net(:[0-9]*)?$/                   ||
        entity_name =~ /^.*windowsphone-int.net(:[0-9]*)?$/          ||
        entity_name =~ /^.*windowsphone.com(:[0-9]*)?$/              ||
        entity_name =~ /^.*wordpress.com(:[0-9]*)?$/                 ||
        entity_name =~ /^.*www.goo.gl(:[0-9]*)?$/                    ||
        entity_name =~ /^.*xmlns.com(:[0-9]*)?$/                     ||
        entity_name =~ /^.*youtu.be(:[0-9]*)?$/                      ||
        entity_name =~ /^.*youtube-nocookie.com(:[0-9]*)?$/          ||
        entity_name =~ /^.*youtube.com(:[0-9]*)?$/                   ||
        entity_name =~ /^.*youtubeeducation.com(:[0-9]*)?$/          ||
        entity_name =~ /^.*ytimg.com(:[0-9]*)?$/                     ||
        entity_name =~ /^.*zendesk.com(:[0-9]*)?$/                   ||
        entity_name =~ /^.*zepheira.com(:[0-9]*)?$/                  ||
        entity_name =~ /^.*1e100.com(:[0-9]*)?$/ )
  end

end
end
end
