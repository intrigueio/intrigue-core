module Intrigue
module Ident
module Check
    class PingIdentiy < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "service",
            :vendor => "PingIdentity",
            :product =>"PingFederate",
            :references => ["https://ping.force.com/Support/PingFederate/Administration/Single-sign-on-no-target796070NEW"],
            :match_details =>"redirect (may be interesting)",
            :version => nil,
            :match_type => :content_headers,
            :match_content =>  /^location:.*startSSO.ping/,
            :examples => ["http://192.234.137.107:80"],
            :verify => ["eGNlbGVuZXJneSNJbnRyaWd1ZTo6RW50aXR5OjpVcmkjaHR0cDovLzE5Mi4yMzQuMTM3LjEwNzo4MA"],
            :paths => ["#{url}"]
          }
        ]
      end

    end
  end
  end
  end
