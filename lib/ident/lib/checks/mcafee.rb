module Intrigue
module Ident
module Check
    class Mcafee < Intrigue::Ident::Check::Base

      def generate_checks(uri)
        [
          {
            :name => "McAfee EPolicy Orchestrator",
            :description => "McAfee EPolicy Orchestrator",
            :type => :content_body,
            :version => nil,
            :content => /McAfee Agent Activity Log/i,
            :paths => ["#{uri}"]
          }
        ]
      end

    end
  end
  end
  end
