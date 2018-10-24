module Intrigue
module Ident
module Check
  class Jive < Intrigue::Ident::Check::Base

    def generate_checks(url)
      [
        {
          :type => "service",
          :vendor => "Jive",
          :tags => [],
          :product =>"Platform",
          :match_details =>"jive login page",
          :match_type => :content_cookies,
          :version => nil,
          :match_content =>  /jive.login.ts=/i,
          :examples => ["https://www.gsd.ouroath.com:443"],
          :paths => ["#{url}"]
        }
      ]
    end
  end
end
end
end
