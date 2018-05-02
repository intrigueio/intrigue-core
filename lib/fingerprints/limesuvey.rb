module Intrigue
  module Fingerprint
    class LimeSurvey < Intrigue::Fingerprint::Base

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            {
              :name => "LimeSurvey",
              :description => "LimeSurvey",
              :type => :content_body,
              :version => "Unknown",
              :content => /Donate to LimeSurvey/
            }
          ]
        }
      end

    end
  end
end
