module Intrigue
module Handler
  class Json < Intrigue::Handler::Base

    def self.type
      "json"
    end

    def process(result, prefix_name=nil)
      # Write it out
      File.open("#{$intrigue_basedir}/tmp/#{prefix_name}#{result.name}.json", "w") do |file|
        file.write(result.export_json)
      end
    end

  end
end
end
