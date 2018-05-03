module Intrigue
  module Fingerprint
    class Cloudfront < Intrigue::Fingerprint::Base

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            {
              :name => "Cloudfront - Error (Body)",
              :description => "Cloudfront - no configured hostname",
              :version => "",
              :type => :content_body,
              :content => /ERROR: The request could not be satisfied/,
              :hide => true
            },
            {
              :name => "Cloudfront - Error (Headers)",
              :description => "Cloudfront - no configured hostname",
              :version => "",
              :type => :content_headers,
              :content => /Error from cloudfront/,
              :hide => true
            },
            {
              :name => "Cloudfront - 403 (Body)",
              :description => "Cloudfront - 403",
              :version => "",
              :type => :content_body,
              :content => /<h1>403 Forbidden<\/h1><\/center>\n<hr><center>cloudflare/,
              :hide => true
            }
          ]
        }
      end

    end
  end
end
