module Intrigue
  module Fingerprint
    class Cloudfront < Intrigue::Fingerprint::Base

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            {
              :name => "Cloudfront - Error",
              :description => "Cloudfront - no configured hostname",
              :version => "",
              :type => :content_body,
              :content => /ERROR: The request could not be satisfied/,
              :hide => true
            },
            {
              :name => "Cloudfront - Error",
              :description => "Cloudfront - no configured hostname",
              :version => "",
              :type => :content_headers,
              :content => /Error from cloudfront/,
              :hide => true
            }
          ]
        }
      end

    end
  end
end
