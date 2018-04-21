module Intrigue
  module Fingerprint
    class LimeSurvey

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            {
              :name => "LimeSurvey",
              :description => "LimeSurvey",
              :type => "content",
              :version => "(Unknown Version)",
              :content => /Donate to LimeSurvey/,
              :test_site => "http://129.186.73.249/index.php/admin"
            }
          ]
        }
      end

    end
  end
end
