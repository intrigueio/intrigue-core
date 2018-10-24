module Intrigue
module Ident
module Check
    class TeamCity < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "application",
            :vendor => "TeamCity",
            :product => "TeamCity",
            :match_details => "TeamCity Continuous Integration",
            :version => nil,
            :match_type => :content_body,
            :match_content =>  /icons\/teamcity.black.svg/i,
            :paths => ["#{url}"]
          }
        ]
      end

    end
  end
  end
  end
