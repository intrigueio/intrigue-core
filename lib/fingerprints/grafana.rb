module Intrigue
  module Fingerprint
    class Grafana < Intrigue::Fingerprint::Base

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            {
              :name => "Grafana",
              :description => "Grafana",
              :version => "Unknown",
              :type => :content_cookies,
              :content => /grafana_sess/
            }
          ]
        }
      end

    end
  end
end
