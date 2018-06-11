module Intrigue
  module Fingerprint
    class Telerik < Intrigue::Fingerprint::Base

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            {
              :name => "Telerik Sitefinity",
              :description => "Telerik Sitefinity is an ASP.NET 2.0-based Content Management System (CMS)",
              :url => "https://www.sitefinity.com/",
              :version => "",
              :type => :content_body,
              :content => /Telerik.Sitefinity.Resources/,
              :dynamic_version => lambda { |x| x.body.match(/Version=([\d\.]+),/).captures[0] }
            }
          ]
        }
      end

    end
  end
end
