module Intrigue
module Handler
  class Json < Intrigue::Handler::Base

    def self.type
      "json"
    end

    def process(result)
      # Write it out
      File.open("#{_export_file_path(result)}.json", "w") do |file|
        file.write(result.export_json)
      end
    end

  end
end
end
