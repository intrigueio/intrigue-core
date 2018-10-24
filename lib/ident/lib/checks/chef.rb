module Intrigue
module Ident
module Check
    class Chef < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "application",
            :vendor => "Chef",
            :product =>"Server",
            :match_details =>"Chef Server",
            :version => nil,
            :match_type => :content_body,
            :match_content =>  /<title>Chef Server<\/title>/,
            :dynamic_version => lambda{|x| _first_body_capture(/Version\ (.*)\ &mdash;/) },
            :paths => ["#{url}"]
          },
          {
            :type => "application",
            :vendor => "Chef",
            :product =>"Server",
            :match_details =>"Chef Server",
            :version => nil,
            :match_type => :content_cookies,
            :match_content =>  /chef-manage/i,
            :paths => ["#{url}"]
          }
        ]
      end

    end
  end
  end
  end
