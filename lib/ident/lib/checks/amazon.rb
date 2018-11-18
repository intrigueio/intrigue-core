module Intrigue
module Ident
module Check
class Amazon < Intrigue::Ident::Check::Base

  def generate_checks(url)
    [
      {
        :type => "service",
        :vendor => "Amazon",
        :product =>"Cloudfront",
        :match_details =>"cloudfront cache header",
        :version => nil,
        :match_type => :content_headers,
        :match_content =>  /via:.*.cloudfront.net \(CloudFront\)/,
        :hide => false,
        :paths => ["#{url}"]
      },
      {
        :type => "service",
        :vendor => "Amazon",
        :product =>"Cloudfront",
        :match_details =>"Cloudfront - no configured hostname error condition",
        :version => nil,
        :match_type => :content_body,
        :match_content =>  /ERROR: The request could not be satisfied/,
        :hide => true,
        :paths => ["#{url}"]
      },
      {
        :type => "service",
        :vendor => "Amazon",
        :product =>"Cloudfront",
        :match_details =>"Cloudfront - no configured hostname error condition",
        :version => nil,
        :match_type => :content_headers,
        :match_content =>  /Error from cloudfront/,
        :hide => true,
        :paths => ["#{url}"]
      },
      {
        :type => "service",
        :vendor => "Amazon",
        :product =>"Cloudfront",
        :match_details =>"Cloudfront - 403 error condition",
        :version => nil,
        :match_type => :content_body,
        :match_content =>  /<h1>403 Forbidden<\/h1><\/center>\n<hr><center>cloudflare/,
        :hide => true,
        :paths => ["#{url}"]
      },
      {
        :tags => ["error_page","hosting_provider"],
        :type => "service",
        :url => "https://aws.amazon.com/elasticloadbalancing/",
        :vendor => "Amazon",
        :product => "Elastic Load Balancer",
        :version => nil,
        :match_type => :content_headers,
        :match_content =>  /awselb\/\d.\d/,
        :match_details =>"Amazon Elastic Load Balancer",
        :hide => true,
        :dynamic_version => lambda { |x| _first_header_capture(/awselb\/(\d.\d)/) },
        :dynamic_version_field => "headers",
        :dynamic_version_regex => /awselb\/(\d.\d)/,
        :verify_sites => ["http://52.4.103.22:80"],
        :paths => ["#{url}"]
      }
    ]
  end
end
end
end
end
