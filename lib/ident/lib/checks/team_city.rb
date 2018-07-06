module Intrigue
module Ident
module Check
    class TeamCity < Intrigue::Ident::Check::Base

      def generate_checks(uri)
        [
          {
            :name => "TeamCity Continuous Integration",
            :description => "TeamCity Continuous Integration",
            :version => nil,
            :type => :content_body,
            :content => /icons\/teamcity.black.svg/i,
            :paths => ["#{uri}"]
          }
        ]
      end

    end
  end
  end
  end
