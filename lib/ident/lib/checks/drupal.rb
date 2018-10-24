module Intrigue
module Ident
module Check
    class Drupal < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "application",
            :vendor => "Drupal",
            :product => "Drupal",
            :tags => ["CMS"],
            :match_details => "Drupal version in page content",
            :version => nil,
            :match_type => :content_body,
            :match_content => /^Drupal [0-9]+\.[0-9]+/,
            :dynamic_version => lambda { |x|
              _first_body_capture(x,/^Drupal ([0-9\.]*?)[ ,<\.].*$/)
            },
            :paths => ["#{url}/CHANGELOG.txt"]
          },
          {
            :type => "application",
            :vendor => "Drupal",
            :product => "Drupal",
            :tags => ["CMS"],
            :match_details => "Drupal headers",
            :version => nil,
            :match_type => :content_headers,
            :match_content =>  /x-generator: Drupal/,
            :dynamic_version => lambda { |x|
              _first_header_capture(x,/x-generator: Drupal\ ([0-9]+)\ \(/i,)
            },
            :paths => ["#{url}"]
          }

        ]
      end

    end
  end
  end
  end
