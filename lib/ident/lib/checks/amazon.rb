module Intrigue
module Ident
module Check
class Amazon < Intrigue::Ident::Check::Base

  def generate_checks(uri)
    [
      {
        :name => "Amazon ELB",
        :description => "Amazon Elastic Load Balancer",
        :url => "https://aws.amazon.com/elasticloadbalancing/",
        :version => nil,
        :tags => ["error_page"],
        :type => :content_headers,
        :content => /awselb\/\d.\d/,
        :hide => true,
        :dynamic_version => lambda { |x| x["details"]["headers"].join("\n").match(/awselb\/(\d.\d)/).captures[0] },
        :verify_sites => ["http://52.4.103.22:80"],
        :paths => ["#{uri}"]
      }
    ]
  end
end
end
end
end
