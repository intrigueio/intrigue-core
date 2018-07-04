module Intrigue
module Ident
module Check
    class Grafana < Intrigue::Ident::Check::Base

      def generate_checks(uri)
        [
          {
            :name => "Grafana",
            :description => "Grafana",
            :version => nil,
            :type => :content_cookies,
            :content => /grafana_sess/i,
            :paths => ["#{uri}"]
          }
        ]
      end

    end
  end
  end
  end
