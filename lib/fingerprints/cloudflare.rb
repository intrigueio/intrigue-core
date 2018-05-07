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
              :description => "Cloudflare Server",
              :version => "",
              :type => :content_headers,
              :content => /cloudflare-nginx/
            },
            {
              :name => "Cloudflare",
              :description => "Cloudflare - Direct IP Access",
              :version => "",
              :type => :content_body,
              :content => /<title>Direct IP access not allowed \| Cloudflare/,
              :hide => true
            },
            {
              :name => "Cloudflare",
              :description => "Cloudflare Error",
              :version => "",
              :type => :content_body,
              :content => /cferror_details/,
              :hide => true
            },
            {
              :name => "Cloudflare",
              :description => "Cloudfront Error - Direct IP Access",
              :version => "",
              :type => :content_body,
              :content => /403\ Forbidden<\/h1><\/center>\n<hr><center>cloudflare<\/center>/,
              :hide => true
            }
          ]
        }
      end

    end
  end
end
