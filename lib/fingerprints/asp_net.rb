module Intrigue
  module Fingerprint
    class AspNet

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            {
              :name => "ASP.NET",
              :description => "ASP.Net Error Message",
              :type => "content",
              :content => /ASP.NET is configured/,
              :dynamic_name => lambda{|x| x.scan(/ASP.NET Version:.*$/)[0].gsub("ASP.NET Version:","").chomp }
            }
          ]
        }
      end

    end
  end
end
