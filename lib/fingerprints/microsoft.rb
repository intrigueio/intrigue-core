module Intrigue
  module Fingerprint
    class Microsoft < Intrigue::Fingerprint::Base

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            {
              :name => "Microsoft Forefront TMG",
              :description => "Microsoft Forefront Threat Management Gateway",
              :version => nil,
              :type => :content_cookies,
              :content => /<title>Microsoft Forefront TMG/
            }
          ]
        }
      end

    end
  end
end
