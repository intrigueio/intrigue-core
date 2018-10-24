module Intrigue
module Ident
module Check
    class Mailchimp < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "application",
            :vendor => "Mailchimp",
            :product =>"Mandrill",
            :match_details =>"login page",
            :match_type => :content_body,
            :version => nil,
            :match_content =>  /<title>Log in to Mandrill/i,
            :paths => ["#{url}"],
            :examples => ["http://107.20.49.246:80"]
          }
        ]
      end

    end
  end
  end
  end
