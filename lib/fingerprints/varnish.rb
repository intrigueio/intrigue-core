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
              :version => "",
              :type => :content_headers,
              :content => /via: [0-9]\.[0-9] varnish/,
              :dynamic_version => lambda{|x| x.each_header{|h,v| if h == "via" && v =~ /varnish/; return v.gsub(" varnish"); end } }
            }
          ]
        }
      end

    end
  end
end
