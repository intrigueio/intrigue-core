module Intrigue
module Ident
module Check
    class Telerik < Intrigue::Ident::Check::Base

      def generate_checks(url)
        [
          {
            :type => "application",
            :vendor => "Telerik",
            :product => "Sitefinity",
            :match_details => "Telerik Sitefinity is an ASP.NET 2.0-based Content Management System (CMS)",
            :url => "https://www.sitefinity.com/",
            :version => nil,
            :match_type => :content_body,
            :match_content =>  /Telerik.Sitefinity.Resources/,
            :dynamic_version => lambda { |x|  _first_body_capture x, /Version=([\d\.]+),/ },
            :examples => [],
            :paths => ["#{url}"]
          },
          {
            :type => "application",
            :vendor => "Telerik",
            :product => "Sitefinity",
            :match_details => "Detect Telerik via a meta generator tag",
            :url => "https://www.sitefinity.com/",
            :version => nil,
            :match_type => :content_body,
            :match_content =>  /<meta\ name=\"Generator\"\ content=\"Sitefinity/,
            :dynamic_version => lambda { |x| _first_body_capture x, /<meta name=\"Generator\" content=\"Sitefinity (.*?)\ \/><link/ },
            :examples => [],
            :paths => ["#{url}"]
          }
        ]
      end

    end
  end
  end
  end
