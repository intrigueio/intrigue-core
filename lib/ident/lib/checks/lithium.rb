module Intrigue
module Ident
module Check
    class Lithium < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "application",
            :vendor => "Lithium",
            :product =>"Lithium",
            :match_details =>"Lithium Community Management",
            :match_type => :content_cookies,
            :version => nil,
            :match_content =>  /LithiumVisitor/i,
            :paths => ["#{url}"]
          },
          {
            :type => "application",
            :vendor => "Lithium",
            :product =>"Lithium",
            :match_details =>"Lithium Community Management",
            :match_type => :content_cookies,
            :version => nil,
            :match_content =>  /LiSESSIONID/i,
            :paths => ["#{url}"]
          }
        ]
      end

    end
  end
  end
  end
