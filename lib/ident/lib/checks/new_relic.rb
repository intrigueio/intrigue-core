module Intrigue
module Ident
module Check
    class NewRelic < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "service",
            :vendor => "NewRelic",
            :product =>"NewRelic",
            :references => ["https://discuss.newrelic.com/t/relic-solution-what-is-bam-nr-data-net-new-relic-browser-monitoring/42055"],
            :match_details =>"NewRelic tracking code",
            :version => nil,
            :match_type => :content_body,
            :match_content =>  /bam.nr-data.net/i,
            :paths => ["#{url}"]
          }
        ]
      end

    end
  end
  end
  end
