module Intrigue
  module Fingerprint
    class Google < Intrigue::Fingerprint::Base

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            {
              :name => "Google",
              :description => "Google Missing Page",
              :type => :content_body,
              :version => "",
              :content => /The requested URL <code>\/<\/code> was not found on this server\./,
              :hide => true
            }
          ]
        }
      end

    end
  end
end
