module Intrigue
module Ident
module Check
    class LimeSurvey < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "application",
            :vendor =>"LimeSurvey",
            :product =>"LimeSurvey",
            :match_details =>"LimeSurvey",
            :match_type => :content_body,
            :version => nil,
            :match_content =>  /Donate to LimeSurvey/,
            :paths => ["#{url}"]
          }
        ]
      end

    end
  end
  end
  end
