module Intrigue
  module Task
    module Prohibited

          def prohibited_entity?(entity)
            if entity.type_string == "IpAddress"
              # 23.x.x.x
              if ( entity.name =~ /^23\..*$/             ||  # akamai
                   entity.name =~ /^2600:1400.*$/        ||  # akamai
                   entity.name =~ /^2600:1409.*$/        ||  # akamai
                   entity.name =~ /^127\.\0\.0\..*$/     ||  # RFC1918
                   entity.name =~ /^10\..*$/              ||  # RFC1918
                   entity.name =~ /^0.0.0.0/ )
                return true
              end
            end

            # Standard exclusions
            if (
                entity.name =~ /^.*1e100.net$/                     ||
                entity.name =~ /^.*2o7.net$/                       ||
                entity.name =~ /^.*akadns.net$/                    ||
                entity.name =~ /^.*akam.net$/                      ||
                entity.name =~ /^.*akamai.net$/                    ||
                entity.name =~ /^.*akamai.com$/                    ||
                entity.name =~ /^.*akamaiedge.net$/                ||
                entity.name =~ /^.*akamaihd-staging.net$/          ||
                entity.name =~ /^.*akamaihd.net$/                  ||
                entity.name =~ /^.*akamaistream.net$/              ||
                entity.name =~ /^.*akamaitechnologies.net$/        ||
                entity.name =~ /^.*akamaitechnologies.com$/        ||
                entity.name =~ /^.*akamaized-staging.net$/         ||
                entity.name =~ /^.*akamaized.net$/                 ||
                entity.name =~ /^.*amazonaws.com$/                 ||
                entity.name =~ /^.*android.clients.google.com$/    ||
                entity.name =~ /^.*android.com$/                   ||
                entity.name =~ /^.*azure-mobile.net$/              ||
                entity.name =~ /^.*azureedge-test.net$/            ||
                entity.name =~ /^.*azureedge.net$/                 ||
                entity.name =~ /^.*azurewebsites.net$/             ||
                entity.name =~ /^.*cloudapp.net$/                  ||
                entity.name =~ /^.*cloudfront.net$/                ||
                entity.name =~ /^.*drupal.org$/                    ||
                entity.name =~ /^.*edgecastcdn.net$/               ||
                entity.name =~ /^.*edgekey.net$/                   ||
                entity.name =~ /^.*edgesuite.net$/                 ||
                entity.name =~ /^.*facebook.com$/                  ||
                entity.name =~ /^.*feeds2.feedburner.com$/         ||
                entity.name =~ /^.*g.co$/                          ||
                entity.name =~ /^.*gandi.net$/                     ||
                entity.name =~ /^.*goo.gl$/                        ||
                entity.name =~ /^.*google-analytics.com$/          ||
                entity.name =~ /^.*google.ca$/                     ||
                entity.name =~ /^.*google.cl$/                     ||
                entity.name =~ /^.*google.co.in$/                  ||
                entity.name =~ /^.*google.co.jp$/                  ||
                entity.name =~ /^.*google.co.uk$/                  ||
                entity.name =~ /^.*google.com$/                    ||
                entity.name =~ /^.*google.com.ar$/                 ||
                entity.name =~ /^.*google.com.au$/                 ||
                entity.name =~ /^.*google.com.br$/                 ||
                entity.name =~ /^.*google.com.co$/                 ||
                entity.name =~ /^.*google.com.mx$/                 ||
                entity.name =~ /^.*google.com.tr$/                 ||
                entity.name =~ /^.*google.com.vn$/                 ||
                entity.name =~ /^.*google.de$/                     ||
                entity.name =~ /^.*google.es$/                     ||
                entity.name =~ /^.*google.fr$/                     ||
                entity.name =~ /^.*google.hu$/                     ||
                entity.name =~ /^.*google.it$/                     ||
                entity.name =~ /^.*google.nl$/                     ||
                entity.name =~ /^.*google.pl$/                     ||
                entity.name =~ /^.*google.pt$/                     ||
                entity.name =~ /^.*googleadapis.com$/              ||
                entity.name =~ /^.*googleapis.cn$/                 ||
                entity.name =~ /^.*googlecommerce.com$/            ||
                entity.name =~ /^.*gstatic.cn$/                    ||
                entity.name =~ /^.*gstatic.com$/                   ||
                entity.name =~ /^.*gvt1.com$/                      ||
                entity.name =~ /^.*gvt2.com$/                      ||
                entity.name =~ /^.*herokussl.com$/                 ||
                entity.name =~ /^.*hubspot.com$/                   ||
                entity.name =~ /^.*instagram.com$/                 ||
                entity.name =~ /^.*localhost$/                     ||
                entity.name =~ /^.*mandrillapp.com$/               ||
                entity.name =~ /^.*marketo.com$/                   ||
                entity.name =~ /^.*metric.gstatic.com$/            ||
                entity.name =~ /^.*microsoft.com$/                 ||
                entity.name =~ /^.*msn.com$/                       ||
                entity.name =~ /^.*oclc.org$/                      ||
                entity.name =~ /^.*ogp.me$/                        ||
                entity.name =~ /^.*outlook.com$/                   ||
                entity.name =~ /^.*outook.com$/                    ||
                entity.name =~ /^.*plus.google.com$/               ||
                entity.name =~ /^.*purl.org$/                      ||
                entity.name =~ /^.*rdfs.org$/                      ||
                entity.name =~ /^.*root-servers.net$/              ||
                entity.name =~ /^.*schema.org$/                    ||
                entity.name =~ /^.*sendgrid.net$/                  ||
                entity.name =~ /^.*secureserver.net$/              ||
                entity.name =~ /^.*statuspage.io$/                 ||
                entity.name =~ /^.*twitter.com$/                   ||
                entity.name =~ /^.*urchin$/                        ||
                entity.name =~ /^.*urchin.com$/                    ||
                entity.name =~ /^.*url.google.com$/                ||
                entity.name =~ /^.*v0cdn.net$/                     ||
                entity.name =~ /^.*w3.org$/                        ||
                entity.name =~ /^.*windows.net$/                   ||
                entity.name =~ /^.*windowsphone-int.net$/          ||
                entity.name =~ /^.*windowsphone.com$/              ||
                entity.name =~ /^.*www.goo.gl$/                    ||
                entity.name =~ /^.*xmlns.com$/                     ||
                entity.name =~ /^.*youtu.be$/                      ||
                entity.name =~ /^.*youtube-nocookie.com$/          ||
                entity.name =~ /^.*youtube.com$/                   ||
                entity.name =~ /^.*youtubeeducation.com$/          ||
                entity.name =~ /^.*ytimg.com$/                     ||
                entity.name =~ /^.*zepheira.com$/                  ||
                entity.name =~ /^.*1e100.com$/
                )
              return true
            end
          end

    end
  end
end
