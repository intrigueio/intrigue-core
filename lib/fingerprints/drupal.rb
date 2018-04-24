module Intrigue
  module Fingerprint
    class Drupal

      def generate_fingerprints(uri)
        [
          {
            :uri => "#{uri}/CHANGELOG.txt",
            :checklist => [
              {
                :name => "Drupal",
                :description => "Drupal CMS",
                :version => "Unknown",
                :type => :content_body,
                :content => /Drupal/,
                :dynamic_version => lambda{|x| x.scan(/Drupal.*,/)[0].gsub("Drupal ","").gsub(",","").chomp }
              }
            ]
          }
        ]
      end

    end
  end
end
