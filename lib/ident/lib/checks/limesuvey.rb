module Intrigue
module Ident
module Check
    class LimeSurvey < Intrigue::Ident::Check::Base

      def generate_checks(uri)
        [
          {
            :name => "LimeSurvey",
            :description => "LimeSurvey",
            :type => :content_body,
            :version => nil,
            :content => /Donate to LimeSurvey/,
            :paths => ["#{uri}"]
          }
        ]
      end

    end
  end
  end
  end
