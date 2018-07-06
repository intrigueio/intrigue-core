module Intrigue
module Ident
module Check
    class Drupal < Intrigue::Ident::Check::Base

      def generate_checks(uri)
        [
          {
            :name => "Drupal",
            :description => "Drupal CMS",
            :version => nil,
            :type => :content_body,
            :content => /Drupal/,
            :dynamic_version => lambda { |x|
              version = x["details"]["hidden_response_data"].scan(/^(Drupal.*)[ ,<\.].*$/)[0]
              return version.first.gsub("Drupal ","").gsub(",","").chomp if version
            },
            :paths => ["#{uri}/CHANGELOG.txt"]
          }
        ]
      end

    end
  end
  end
  end
