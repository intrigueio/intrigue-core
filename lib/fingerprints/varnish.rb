module Intrigue
  module Fingerprint
    class Varnish < Intrigue::Fingerprint::Base

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            {
              :name => "Varnish",
              :description => "Varnish Proxy",
              :version => nil,
              :type => :content_headers,
              :content => /via: [0-9]\.[0-9] varnish/,
              :dynamic_version => lambda{ |x|
                m = nil
                x.each_header{|h,v| m = v if (h == "via" && v =~ /varnish/) }
                m.gsub("varnish ","") if m
              }
            }
          ]
        }
      end

    end
  end
end
