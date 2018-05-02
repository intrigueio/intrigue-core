module Intrigue
  module Fingerprint
    class Cloudfront < Intrigue::Fingerprint::Base

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            {
              :name => "Cloudfront - Missing Page",
              :description => "Cloudfront - no configured hostname",
              :version => "",
              :type => :content_body,
              :content => /ERROR: The request could not be satisfied/,
              :hide => true
            }
          ]
        }
      end

    end
  end
end
