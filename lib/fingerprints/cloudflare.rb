module Intrigue
  module Fingerprint
    class Cloudflare < Intrigue::Fingerprint::Base

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            {
              :name => "Cloudflare",
              :description => "Cloudflare Accelerated Page",
              :version => "",
              :type => :content_cookies,
              :content => /__cfduid/
            },
            {
              :name => "Cloudflare",
              :description => "Cloudfront ",
              :version => "",
              :type => :content_headers,
              :content => /cloudflare-nginx/
            },
            {
              :name => "Cloudflare",
              :description => "Cloudfront - Direct IP Access",
              :version => "",
              :type => :content_body,
              :content => /<title>Direct IP access not allowed \| Cloudflare/,
              :hide => true
            },
            {
              :name => "Cloudflare",
              :description => "Cloudfront Error",
              :version => "",
              :type => :content_body,
              :content => /cferror_details/,
              :hide => true
            }
          ]
        }
      end

    end
  end
end
