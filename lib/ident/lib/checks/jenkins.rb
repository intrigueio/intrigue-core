module Intrigue
module Ident
module Check
    class Jenkins < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          { # might need to be its own, but haven't seen it yet outside jenkins
            :type => "application",
            :vendor => "Jenkins",
            :product => "Hudson",
            :match_details => "Hudson",
            :version => nil,
            :match_type => :content_headers,
            :match_content =>  /x-hudson/i,
            :dynamic_version => lambda { |x| _first_header_capture(x, /^x-hudson:(.*)$/) },
            :paths => ["#{url}"]
          },
          {
            :type => "application",
            :vendor => "Jenkins",
            :product =>"Jenkins",
            :match_details =>"Jenkins",
            :version => nil,
            :match_type => :content_headers,
            :match_content =>  /X-Jenkins-Session/i,
            :paths => ["#{url}"]
          },
          {
            :type => "application",
            :vendor => "Jenkins",
            :product =>"Jenkins",
            :match_details =>"Jenkins",
            :version => nil,
            :match_type => :content_headers,
            :match_content =>  /x-jenkins/i,
            :dynamic_version => lambda { |x| _first_header_capture(x, /^x-jenkins:(.*)$/) },
            :paths => ["#{url}"]
          }
        ]
      end

    end
  end
  end
  end
