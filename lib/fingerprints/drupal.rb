module Intrigue
  module Fingerprint
    class Drupal < Intrigue::Fingerprint::Base

      def generate_fingerprints(uri)
        [
          {
            :uri => "#{uri}/CHANGELOG.txt",
            :checklist => [
              {
                :name => "Drupal",
                :description => "Drupal CMS",
                :version => nil,
                :type => :content_body,
                :content => /Drupal/,
                :dynamic_version => lambda { |x|
                  version = x.body.scan(/^(Drupal.*)[ ,<\.].*$/)[0]
                  return version.first.gsub("Drupal ","").gsub(",","").chomp if version
                }
              }
            ]
          }
        ]
      end

    end
  end
end
