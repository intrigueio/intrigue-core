module Intrigue
module Ident
module Check
    class Tableau < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "application",
            :vendor => "TableauSoftware",
            :product => "Tableau Server",
            :match_details => "Tableau Server - unique string",
            :version => nil,
            :references => ["https://community.tableau.com/thread/165653"],
            :match_type => :content_body,
            :match_content =>  /<meta name="vizportal-config" data-buildId=/i,
            :examples => ["http://137.154.26.56:80"],
            :paths => ["#{url}"]
          }
        ]
      end

    end
  end
  end
  end
