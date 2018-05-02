module Intrigue
  module Fingerprint
    class Cloudflare < Intrigue::Fingerprint::Base

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            {
              :name => "Cloudflare",
              :description => "Cloudfront Accelerated Page",
              :version => "",
              :type => :content_cookies,
              :content => /__cfduid/
            }
          ]
        }
      end

    end
  end
end
