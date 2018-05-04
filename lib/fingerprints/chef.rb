module Intrigue
  module Fingerprint
    class Chef < Intrigue::Fingerprint::Base

      def generate_fingerprints(uri)
        {
          :uri => "#{uri}",
          :checklist => [
            {
              :name => "Chef Server",
              :description => "Chef Server",
              :version => nil,
              :type => :content_body,
              :content => /<title>Chef Server<\/title>/,
              :dynamic_version => lambda{|x| x.body.scan(/Version\ (.*)\ &mdash;/)[0].first }
            },
            {
              :name => "Chef Server",
              :description => "Chef Server",
              :version => nil,
              :type => :content_cookies,
              :content => /chef-manage/
            }
          ]
        }
      end

    end
  end
end
