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
                :dynamic_version => lambda{|x| x.body.scan(/^(Drupal.*)[ ,<\.].*$/)[0].first.gsub("Drupal ","").gsub(",","").chomp }
              }
            ]
          }
        ]
      end

    end
  end
end
