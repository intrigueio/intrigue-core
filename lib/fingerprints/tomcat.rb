module Intrigue
  module Fingerprint
    class Tomcat

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
              :test_site => "https://cms.msu.montana.edu/",
              :dynamic_version => lambda{|x| x.body.scan(/<title>.*<\/title>/)[0].gsub("<title>","").gsub("Tomcat","").gsub(" - Error report</title>","").chomp }
            }
          ]
        }
      end
    end
  end
end
