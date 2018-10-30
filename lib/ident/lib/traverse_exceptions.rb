module Intrigue
module Ident
module TraverseExceptions

    def non_traversable?(entity_name, type_string="Domain")
      out = false

      if type_string == "IpAddress"
        out = true if (
            # Skip Akamai
            entity_name =~ /^23\..*$/              ||
            entity_name =~ /^2600:1400.*$/         ||
            entity_name =~ /^2600:1409.*$/         ||

            # Skip Incapsula... lots of annoying scan results here
            entity_name =~ /107\.154\.*/           ||

            # RFC1918
            #entity_name =~ /^172\.16\..*$/         ||
            #entity_name =~ /^192\.168\..*$/        ||
            #entity_name =~ /^10\..*$/              ||

            # localhost
            entity_name =~ /^127\..*$/             ||
            entity_name =~ /^0.0.0.0/ )
      end

      if type_string == "Domain" || type_string == "DnsRecord" || type_string == "Uri"
        # Standard exclusions
        out = true if (
            entity_name =~ /^.*\.[a-z]-msedge.net(:[0-9]*)?$/              ||
            entity_name =~ /^.*\.1e100.net(:[0-9]*)?$/                     ||
            entity_name =~ /^.*\.2o7.net(:[0-9]*)?$/                       ||
            entity_name =~ /^.*\.adobecqms.net(:[0-9]*)?$/                 ||
            entity_name =~ /^.*\.akadns.net(:[0-9]*)?$/                    ||
            entity_name =~ /^.*\.akam.net(:[0-9]*)?$/                      ||
            entity_name =~ /^.*\.akamai.net(:[0-9]*)?$/                    ||
            entity_name =~ /^.*\.akamai.com(:[0-9]*)?$/                    ||
            entity_name =~ /^.*\.akamaiedge.net(:[0-9]*)?$/                ||
            entity_name =~ /^.*\.akamaiedge-staging.net(:[0-9]*)?$/        ||
            entity_name =~ /^.*\.akamaihd-staging.net(:[0-9]*)?$/          ||
            entity_name =~ /^.*\.akamaihd.net(:[0-9]*)?$/                  ||
            entity_name =~ /^.*\.akamaistream.net(:[0-9]*)?$/              ||
            entity_name =~ /^.*\.akamaitechnologies.net(:[0-9]*)?$/        ||
            entity_name =~ /^.*\.akamaitechnologies.com(:[0-9]*)?$/        ||
            entity_name =~ /^.*\.akamaized-staging.net(:[0-9]*)?$/         ||
            entity_name =~ /^.*\.akamaized.net(:[0-9]*)?$/                 ||
            entity_name =~ /^.*\.amazonaws.com(:[0-9]*)?$/                 ||
            entity_name =~ /^.*\.android.clients.google.com(:[0-9]*)?$/    ||
            entity_name =~ /^.*\.android.com(:[0-9]*)?$/                   ||
            entity_name =~ /^.*\.anubisnetworks.com(:[0-9]*)?$/            ||
            entity_name =~ /^.*\.apache.org(:[0-9]*)?$/                    ||
            entity_name =~ /^.*\.\.arpa(:[0-9]*)?$/                        ||
            entity_name =~ /^.*\.atlinkservices.com(:[0-9]*)?$/            ||
            entity_name =~ /^.*\.azure-mobile.net(:[0-9]*)?$/              ||
            entity_name =~ /^.*\.azureedge-test.net(:[0-9]*)?$/            ||
            entity_name =~ /^.*\.azureedge.net(:[0-9]*)?$/                 ||
            entity_name =~ /^.*\.azurewebsites.net(:[0-9]*)?$/             ||
            entity_name =~ /^.*\.bfi0.com(:[0-9]*)?$/                      ||
            entity_name =~ /^.*\.bigcommerce.com(:[0-9]*)?$/               ||
            entity_name =~ /^.*\.bluehost.com(:[0-9]*)?$/                  ||
            entity_name =~ /^.*\.brightcove.com(:[0-9]*)?$/                ||
            entity_name =~ /^.*\.bronto.com(:[0-9]*)?$/                    ||
            entity_name =~ /^.*\.bydiscourse.com(:[0-9]*)?$/               ||
            entity_name =~ /^.*\.chtah.com(:[0-9]*)?$/                     ||
            entity_name =~ /^.*\.cheetahmail.com(:[0-9]*)?$/               ||
            entity_name =~ /^.*\.clickdimensions.com(:[0-9]*)?$/           ||
            entity_name =~ /^.*\.cloudapp.net(:[0-9]*)?$/                  ||
            entity_name =~ /^.*\.cloudfront.net(:[0-9]*)?$/                ||
            entity_name =~ /^.*\.cloudflare-dns.com(:[0-9]*)?$/            ||
            entity_name =~ /^.*\.convertlanguage.com(:[0-9]*)?$/           ||
            entity_name =~ /^.*\.corporate-ir.net(:[0-9]*)?$/              ||
            entity_name =~ /^.*\.decipherinc.com(:[0-9]*)?$/               ||
            entity_name =~ /^.*\.discourse.org(:[0-9]*)?$/                 ||
            entity_name =~ /^.*\.drupal.org(:[0-9]*)?$/                    ||
            entity_name =~ /^.*\.ed[0-9]+.com(:[0-9]*)?$/                  ||
            entity_name =~ /^.*\.edgecastcdn.net(:[0-9]*)?$/               ||
            entity_name =~ /^.*\.edgekey.net(:[0-9]*)?$/                   ||
            entity_name =~ /^.*\.edgekey-staging.net(:[0-9]*)?$/           ||
            entity_name =~ /^.*\.edgesuite.net(:[0-9]*)?$/                 ||
            entity_name =~ /^.*\.egnyte.com(:[0-9]*)?$/                    ||
            entity_name =~ /^.*\.eloqua.com(:[0-9]*)?$/                    ||
            entity_name =~ /^.*\.exacttarget.com(:[0-9]*)?$/               ||
            entity_name =~ /^.*\.facebook.com(:[0-9]*)?$/                  ||
            entity_name =~ /^.*\.fastly.net(:[0-9]*)?$/                    ||
            entity_name =~ /^.*\.feeds2.feedburner.com(:[0-9]*)?$/         ||
            entity_name =~ /^.*\.footprintdns.com(:[0-9]*)?$/              ||
            entity_name =~ /^.*\.force.com(:[0-9]*)?$/                     ||
            entity_name =~ /^.*\.g.co(:[0-9]*)?$/                          ||
            entity_name =~ /^.*\.gandi.net(:[0-9]*)?$/                     ||
            entity_name =~ /^.*\.gcs-web.com(:[0-9]*)?$/                   ||
            entity_name =~ /^.*\.ghs.google.com(:[0-9]*)?$/                ||
            entity_name =~ /^.*\.github.com(:[0-9]*)?$/                    ||
            entity_name =~ /^.*\.goo.gl(:[0-9]*)?$/                        ||
            entity_name =~ /^.*\.google-analytics.com(:[0-9]*)?$/          ||
            entity_name =~ /^.*\.githubapp.com(:[0-9]*)?$/                 ||
            entity_name =~ /^.*\.google.ca(:[0-9]*)?$/                     ||
            entity_name =~ /^.*\.google.cl(:[0-9]*)?$/                     ||
            entity_name =~ /^.*\.google.co.in(:[0-9]*)?$/                  ||
            entity_name =~ /^.*\.google.co.jp(:[0-9]*)?$/                  ||
            entity_name =~ /^.*\.google.co.uk(:[0-9]*)?$/                  ||
            entity_name =~ /^.*\.google.com(:[0-9]*)?$/                    ||
            entity_name =~ /^.*\.google.com.ar(:[0-9]*)?$/                 ||
            entity_name =~ /^.*\.google.com.au(:[0-9]*)?$/                 ||
            entity_name =~ /^.*\.google.com.br(:[0-9]*)?$/                 ||
            entity_name =~ /^.*\.google.com.co(:[0-9]*)?$/                 ||
            entity_name =~ /^.*\.google.com.mx(:[0-9]*)?$/                 ||
            entity_name =~ /^.*\.google.com.tr(:[0-9]*)?$/                 ||
            entity_name =~ /^.*\.google.com.vn(:[0-9]*)?$/                 ||
            entity_name =~ /^.*\.google.de(:[0-9]*)?$/                     ||
            entity_name =~ /^.*\.google.es(:[0-9]*)?$/                     ||
            entity_name =~ /^.*\.google.fr(:[0-9]*)?$/                     ||
            entity_name =~ /^.*\.google.hu(:[0-9]*)?$/                     ||
            entity_name =~ /^.*\.google.it(:[0-9]*)?$/                     ||
            entity_name =~ /^.*\.google.nl(:[0-9]*)?$/                     ||
            entity_name =~ /^.*\.google.pl(:[0-9]*)?$/                     ||
            entity_name =~ /^.*\.google.pt(:[0-9]*)?$/                     ||
            entity_name =~ /^.*\.googleadapis.com(:[0-9]*)?$/              ||
            entity_name =~ /^.*\.googleapis.cn(:[0-9]*)?$/                 ||
            entity_name =~ /^.*\.googlecommerce.com(:[0-9]*)?$/            ||
            entity_name =~ /^.*\.googlehosted.com(:[0-9]*)?$/              ||
            entity_name =~ /^.*\.googlemail.com(:[0-9]*)?$/                ||
            entity_name =~ /^.*\.googlevideo.com(:[0-9]*)?$/               ||
            entity_name =~ /^.*\.gigya.com(:[0-9]*)?$/                     ||
            entity_name =~ /^.*\.gridserver.com(:[0-9]*)?$/                ||
            entity_name =~ /^.*\.gstatic.cn(:[0-9]*)?$/                    ||
            entity_name =~ /^.*\.gstatic.com(:[0-9]*)?$/                   ||
            entity_name =~ /^.*\.gvt1.com(:[0-9]*)?$/                      ||
            entity_name =~ /^.*\.gvt2.com(:[0-9]*)?$/                      ||
            entity_name =~ /^.*\.herokuapp.com(:[0-9]*)?$/                 ||
            entity_name =~ /^.*\.herokudns.com(:[0-9]*)?$/                 ||
            entity_name =~ /^.*\.herokussl.com(:[0-9]*)?$/                 ||
            entity_name =~ /^.*\.hostgator.com(:[0-9]*)?$/                 ||
            entity_name =~ /^.*\.hscoscdn[0-9]+.net(:[0-9]*)?$/            ||
            entity_name =~ /^.*\.hubspot.com(:[0-9]*)?$/                   ||
            entity_name =~ /^.*\.hubspot.net(:[0-9]*)?$/                   ||
            entity_name =~ /^.*\.incapdns.net(:[0-9]*)?$/                  ||
            entity_name =~ /^.*\.incapsula.com(:[0-9]*)?$/                 ||
            entity_name =~ /^.*\.ink1001.com(:[0-9]*)?$/                   || # Movable Ink
            entity_name =~ /^.*\.instagram.com(:[0-9]*)?$/                 ||
            entity_name =~ /^.*\.int-i.net(:[0-9]*)?$/                     || # https://intinc.com/company/
            entity_name =~ /^.*\.invision.net(:[0-9]*)?$/                  ||
            entity_name =~ /^.*\.jobing.com(:[0-9]*)?$/                    ||
            entity_name =~ /^.*\.localhost(:[0-9]*)?$/                     ||
            entity_name =~ /^.*\.lookbookhq.com(:[0-9]*)?$/                ||
            entity_name =~ /^.*\.linkedin.com(:[0-9]*)?$/                  ||
            entity_name =~ /^.*\.live.net(:[0-9]*)?$/                      ||
            entity_name =~ /^.*\.live.com(:[0-9]*)?$/                      ||
            entity_name =~ /^.*\.lync.com(:[0-9]*)?$/                      ||
            entity_name =~ /^.*\.mailgun.info(:[0-9]*)?$/                  ||
            entity_name =~ /^.*\.mailgun.org(:[0-9]*)?$/                   ||
            entity_name =~ /^.*\.mailketeer.com(:[0-9]*)?$/                ||
            entity_name =~ /^.*\.mandrillapp.com(:[0-9]*)?$/               ||
            entity_name =~ /^.*\.marketo.com(:[0-9]*)?$/                   ||
            entity_name =~ /^.*\.metric.gstatic.com(:[0-9]*)?$/            ||
            entity_name =~ /^.*\.mktossl.com(:[0-9]*)?$/                   ||
            entity_name =~ /^.*\.mktoweb.com(:[0-9]*)?$/                   ||
            entity_name =~ /^.*\.mkto-[a-z]+[0-9]+.com(:[0-9]*)?$/         || # marketo branding domain
            entity_name =~ /^.*\.microsoft.com(:[0-9]*)?$/                 ||
            entity_name =~ /^.*\.microsoftonline.com(:[0-9]*)?$/           ||
            entity_name =~ /^.*\.mpmsx.net(:[0-9]*)?$/                     ||
            entity_name =~ /^.*\.mtsvc.net(:[0-9]*)?$/                     ||
            entity_name =~ /^.*\.msn.com(:[0-9]*)?$/                       ||
            entity_name =~ /^.*\.oclc.org(:[0-9]*)?$/                      ||
            entity_name =~ /^.*\.office.com(:[0-9]*)?$/                    ||
            entity_name =~ /^.*\.office.net(:[0-9]*)?$/                    ||
            entity_name =~ /^.*\.office365.com(:[0-9]*)?$/                 ||
            entity_name =~ /^.*\.outlook.com(:[0-9]*)?$/                   ||
            entity_name =~ /^.*\.ogp.me(:[0-9]*)?$/                        ||
            entity_name =~ /^.*\.outlook.com(:[0-9]*)?$/                   ||
            entity_name =~ /^.*\.pardot.com(:[0-9]*)?$/                    ||
            entity_name =~ /^.*\.parklogic.com(:[0-9]*)?$/                 ||
            entity_name =~ /^.*\.photorank.me(:[0-9]*)?$/                  ||
            entity_name =~ /^.*\.plus.google.com(:[0-9]*)?$/               ||
            entity_name =~ /^.*\.posterous.com(:[0-9]*)?$/                 ||
            entity_name =~ /^.*\.purl.org(:[0-9]*)?$/                      ||
            entity_name =~ /^.*\.q4web.com(:[0-9]*)?$/                     ||
            entity_name =~ /^.*\.rdfs.org(:[0-9]*)?$/                      ||
            entity_name =~ /^.*\.root-servers.net(:[0-9]*)?$/              ||
            entity_name =~ /^.*\.schema.org(:[0-9]*)?$/                    ||
            entity_name =~ /^.*\.salesforce.com(:[0-9]*)?$/                ||
            entity_name =~ /^.*\.sendgrid.net(:[0-9]*)?$/                  ||
            entity_name =~ /^.*\.secureserver.net(:[0-9]*)?$/              ||
            entity_name =~ /^.*\.sharepoint.com(:[0-9]*)?$/                ||
            entity_name =~ /^.*\.sharepointonline.com(:[0-9]*)?$/          ||
            entity_name =~ /^.*\.siftscience.com(:[0-9]*)?$/               ||
            entity_name =~ /^.*\.silverpop.com(:[0-9]*)?$/                 ||
            entity_name =~ /^.*\.squarespace.com(:[0-9]*)?$/               ||
            entity_name =~ /^.*\.statuspage.io(:[0-9]*)?$/                 ||
            entity_name =~ /^.*\.statusio.com(:[0-9]*)?$/                  ||
            entity_name =~ /^.*\.sumocdn.net(:[0-9]*)?$/                   ||
            entity_name =~ /^.*\.twitter.com(:[0-9]*)?$/                   ||
            entity_name =~ /^.*\.uberflip.com(:[0-9]*)?$/                  ||
            entity_name =~ /^.*\.ultradns.com(:[0-9]*)?$/                  ||
            entity_name =~ /^.*\.unifiedlayer.com(:[0-9]*)?$/              ||
            entity_name =~ /^.*\.urchin.com(:[0-9]*)?$/                    ||
            entity_name =~ /^.*\.url.google.com(:[0-9]*)?$/                ||
            entity_name =~ /^.*\.v0cdn.net(:[0-9]*)?$/                     ||
            entity_name =~ /^.*\.volusion.com(:[0-9]*)?$/                  ||
            entity_name =~ /^.*\.w3.org(:[0-9]*)?$/                        ||
            entity_name =~ /^.*\.websitewelcome.com(:[0-9]*)?$/            ||
            entity_name =~ /^.*\.weebly.com(:[0-9]*)?$/                    ||
            entity_name =~ /^.*\.windows.net(:[0-9]*)?$/                   ||
            entity_name =~ /^.*\.windowsphone-int.net(:[0-9]*)?$/          ||
            entity_name =~ /^.*\.windowsphone.com(:[0-9]*)?$/              ||
            entity_name =~ /^.*\.wordpress.com(:[0-9]*)?$/                 ||
            entity_name =~ /^.*\.wpengine.com(:[0-9]*)?$/                  ||
            entity_name =~ /^.*\.www.goo.gl(:[0-9]*)?$/                    ||
            entity_name =~ /^.*\.xmlns.com(:[0-9]*)?$/                     ||
            entity_name =~ /^.*\.youtu.be(:[0-9]*)?$/                      ||
            entity_name =~ /^.*\.youtube-nocookie.com(:[0-9]*)?$/          ||
            entity_name =~ /^.*\.youtube.com(:[0-9]*)?$/                   ||
            entity_name =~ /^.*\.youtubeeducation.com(:[0-9]*)?$/          ||
            entity_name =~ /^.*\.ytimg.com(:[0-9]*)?$/                     ||
            entity_name =~ /^.*\.zendesk.com(:[0-9]*)?$/                   ||
            entity_name =~ /^.*\.zepheira.com(:[0-9]*)?$/                  ||
            entity_name =~ /^.*\.1e100.com(:[0-9]*)?$/ )
      end

    out
    end
end
end
end
