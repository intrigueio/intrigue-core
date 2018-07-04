module Intrigue
module Ident
module Check
    class Tomcat < Intrigue::Ident::Check::Base

      def generate_checks(uri)
        [
          {
            :name => "Apache Tomcat",
            :description => "Tomcat Application Server",
            :type => :content_body,
            :version => nil,
            :content => /<title>Apache Tomcat/,
            :dynamic_version => lambda{|x| x.body.scan(/<title>(.*)<\/title>/)[0].first.gsub("Apache Tomcat/","").gsub(" - Error report","").chomp },
            :paths => ["#{uri}"]
          }
        ]
      end
    end
end
end
end
