module Intrigue
  module Fingerprint
    class Example

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}/CHANGELOG.txt",
          :checklist => [
            {
              :name => "Drupal",
              :description => "Drupal CMS",
              :version => "(Unknown Version)",
              :type => "content",
              :content => /Drupal/,
              :dynamic_name => lambda{|x| x.scan(/Drupal.*,/)[0].gsub(",","").chomp }
            }
          ]
        }
      end

    end
  end
end
