module Intrigue
module Ident
module Check
    class Sailpoint < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "application",
            :vendor => "Sailpoint",
            :product => "IdentityQ",
            :references => [
              "https://www.sailpoint.com/identity-management-software-identityiq/"
            ],
            :match_details => "Main page of a sailpoint identityq instance",
            :version => nil,
            :match_type => :content_body,
            :match_content =>  /<title>SailPoint IdentityIQ/i,
            :paths => ["#{url}"]
          }
        ]
      end

    end
  end
  end
  end
