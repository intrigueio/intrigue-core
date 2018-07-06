module Intrigue
module Ident
module Check
    class Chef < Intrigue::Ident::Check::Base

      def generate_checks(uri)
        [
          {
            :name => "Chef Server",
            :description => "Chef Server",
            :version => nil,
            :type => :content_body,
            :content => /<title>Chef Server<\/title>/,
            :dynamic_version => lambda{|x| x["details"]["hidden_response_data"].scan(/Version\ (.*)\ &mdash;/)[0].first },
            :paths => ["#{uri}"]
          },
          {
            :name => "Chef Server",
            :description => "Chef Server",
            :version => nil,
            :type => :content_cookies,
            :content => /chef-manage/i,
            :paths => ["#{uri}"]
          }
        ]
      end

    end
  end
  end
  end
