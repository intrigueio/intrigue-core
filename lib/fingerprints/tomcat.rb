module Intrigue
  module Fingerprint
    class Tomcat < Intrigue::Fingerprint::Base

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            {
              :name => "Apache Tomcat",
              :description => "Tomcat Application Server",
              :type => :content_body,
              :version => "Unknown",
              :content => /<title>Apache Tomcat/,
              :dynamic_version => lambda{|x| x.body.scan(/<title>(.*)<\/title>/)[0].first.gsub("Apache Tomcat/","").gsub(" - Error report","").chomp }
            }
          ]
        }
      end
    end
  end
end
