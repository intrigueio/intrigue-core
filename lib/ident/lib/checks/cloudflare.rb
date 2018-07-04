module Intrigue
module Ident
module Check
    class Cloudflare < Intrigue::Ident::Check::Base

      def generate_checks(uri)
        [
          {
            :name => "Cloudflare",
            :description => "Cloudflare Accelerated Page",
            :version => "",
            :type => :content_cookies,
            :content => /__cfduid/i,
            :paths => ["#{uri}"]
          },
          {
            :name => "Cloudflare",
            :description => "Cloudflare Server",
            :version => "",
            :type => :content_headers,
            :content => /cloudflare-nginx/i,
            :paths => ["#{uri}"]
          },
          {
            :name => "Cloudflare",
            :description => "Cloudflare - Direct IP Access",
            :version => "",
            :type => :content_body,
            :content => /<title>Direct IP access not allowed \| Cloudflare/,
            :hide => true,
            :paths => ["#{uri}"]
          },
          {
            :name => "Cloudflare",
            :description => "Cloudflare Error",
            :version => "",
            :type => :content_body,
            :content => /cferror_details/,
            :hide => true,
            :paths => ["#{uri}"]
          },
          {
            :name => "Cloudflare",
            :description => "Cloudfront Error - Direct IP Access",
            :version => "",
            :type => :content_body,
            :content => /403\ Forbidden<\/h1><\/center>\n<hr><center>cloudflare<\/center>/,
            :hide => true,
            :paths => ["#{uri}"]
          }
        ]
      end

    end
  end
  end
  end
