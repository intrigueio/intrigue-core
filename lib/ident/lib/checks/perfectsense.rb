module Intrigue
module Ident
module Check
  class Perfectsense < Intrigue::Ident::Check::Base

    def generate_checks(url)
      [
        {
          :type => "application",
          :vendor => "PerfectSense",
          :tags => [],
          :product =>"Brightspot",
          :match_details =>"server header",
          :version => nil,
          :references => [],
          :match_type => :content_headers,
          :match_content =>  /x-powered-by: Brightspot/i,
          :examples => [],
          :verify => [],
          :paths => ["#{url}"]
        }
      ]
    end
  end
end
end
end
