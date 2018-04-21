module Intrigue
  module Fingerprint
    class Spring

      def generate_fingerprints(uri)
        [{
          :uri => "#{uri}/thispagedoesnotexist-#{rand(10000000)}",
          :checklist => [{
            :name => "Spring",
            :description => "Standard Spring Error Message",
            :type => "content",
            :version => "(Unknown Version)",
            :content =>  /{"timestamp":\d.*,"status":999,"error":"None","message":"No message available"}/,
            :test_site => "https://pcr.apple.com",
            :references => ["https://github.com/spring-projects/spring-boot"]
          }]},
        {
          :uri => "#{uri}/error.json",
          :checklist => [{
            :name => "Spring",
            :version => "(Unknown Version)",
            :description => "Standard Spring MVC error page",
            :type => "content",
            :content => /{"timestamp":\d.*,"status":999,"error":"None","message":"No message available"}/,
            :test_site => "https://pcr.apple.com"
          }]}
        ]
      end

    end
  end
end
