module Intrigue
module Handler
  class Json < Intrigue::Handler::Base

    def self.type
      "json"
    end

    def process(result, options)
      # Write it out
      File.open("#{_export_file_path(result)}.json", "w") do |file|
        file.write(JSON.pretty_generate(result.export_hash))
      end
    end

  end
end
end
