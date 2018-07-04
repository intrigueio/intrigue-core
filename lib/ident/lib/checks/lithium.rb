module Intrigue
module Ident
module Check
    class Lithium < Intrigue::Ident::Check::Base

      def generate_checks(uri)
        [
          {
            :name => "Lithum ",
            :description => "Lithium Community Management",
            :type => :content_cookies,
            :version => nil,
            :content => /LithiumVisitor/i,
            :paths => ["#{uri}"]
          },
          {
            :name => "Lithum",
            :description => "Lithium Community Management",
            :type => :content_cookies,
            :version => nil,
            :content => /LiSESSIONID/i,
            :paths => ["#{uri}"]
          }
        ]
      end

    end
  end
  end
  end
