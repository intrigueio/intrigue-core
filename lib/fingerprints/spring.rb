module Intrigue
  module Fingerprint
    class Spring

      def generate_fingerprints(uri)
        [{
          :uri => "#{uri}/donotbealarmedthisisjusttestingagenericerrorpage",
          :checklist => [{
            :name => "Spring",
            :description => "Standard Spring Error Message",
            :type => :content_body,
            :version => "Unknown",
            :content =>  /{"timestamp":\d.*,"status":999,"error":"None","message":"No message available"}/,
            :references => ["https://github.com/spring-projects/spring-boot"]
          }]},
        {
          :uri => "#{uri}/error.json",
          :checklist => [{
            :name => "Spring",
            :description => "Standard Spring MVC error page",
            :type => :content_body,
            :version => "Unknown",
            :content => /{"timestamp":\d.*,"status":999,"error":"None","message":"No message available"}/
          }]}
        ]
      end

    end
  end
end
