module Intrigue
  module Fingerprint
    class Lithium < Intrigue::Fingerprint::Base

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            {
              :name => "Lithum ",
              :description => "Lithium Community Management",
              :type => :content_cookies,
              :version => nil,
              :content => /LithiumVisitor/i
            },
            {
              :name => "Lithum",
              :description => "Lithium Community Management",
              :type => :content_cookies,
              :version => nil,
              :content => /LiSESSIONID/i
            }
          ]
        }
      end

    end
  end
end
