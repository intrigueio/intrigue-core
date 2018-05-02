module Intrigue
  module Fingerprint
    class Cpanel < Intrigue::Fingerprint::Base

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            {
              :name => "cPanel Hosted - Missing Page",
              :description => "cPanel Hosted, but either misconfigured, or accessed via ip vs hostname?",
              :version => "",
              :type => :content_body,
              :content => /URL=\/cgi-sys\/defaultwebpage.cgi/,
              :hide => true
            }
          ]
        }
      end

    end
  end
end
