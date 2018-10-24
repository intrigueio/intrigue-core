module Intrigue
module Ident
module Check
    class Blueimp < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "application",
            :vendor => "blueimp",
            :product =>"JQuery File Upload",
            :match_details =>"match string in the page",
            :match_type => :content_body,
            :version => nil,
            :match_content =>  /jquery.fileupload/i,
            :paths => ["#{url}"]
          }
        ]
      end

    end
  end
  end
  end
