module Intrigue
module Ident
module Check
    class Cloudfront < Intrigue::Ident::Check::Base

      def generate_checks(uri)
        [
          {
            :name => "Cloudfront - Error (Body)",
            :description => "Cloudfront - no configured hostname",
            :version => "",
            :type => :content_body,
            :content => /ERROR: The request could not be satisfied/,
            :hide => true,
            :paths => ["#{uri}"]
          },
          {
            :name => "Cloudfront - Error (Headers)",
            :description => "Cloudfront - no configured hostname",
            :version => "",
            :type => :content_headers,
            :content => /Error from cloudfront/,
            :hide => true,
            :paths => ["#{uri}"]
          },
          {
            :name => "Cloudfront - 403 (Body)",
            :description => "Cloudfront - 403",
            :version => "",
            :type => :content_body,
            :content => /<h1>403 Forbidden<\/h1><\/center>\n<hr><center>cloudflare/,
            :hide => true,
            :paths => ["#{uri}"]
          }
        ]
      end

    end
  end
  end
  end
