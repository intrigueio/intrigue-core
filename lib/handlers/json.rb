module Intrigue
module Handler
  class Json < Intrigue::Handler::Base

    def self.type
      "json"
    end

    def process(result)
      # Write it out
      File.open("./tmp/#{result.name}.json", "w") do |file|
        file.write(result.export_json)
      end
    end

  end
end
end
