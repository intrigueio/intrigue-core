module Intrigue
module Handler
  class Json < Intrigue::Handler::Base

    def self.type
      "json"
    end

    def process(result, name=nil)
      # Write it out
      File.open("#{$intrigue_basedir}/tmp/#{name || result.name}.json", "w") do |file|
        file.write(result.export_json)
      end
    end

  end
end
end
