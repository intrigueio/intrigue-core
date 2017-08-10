module Intrigue
module Handler
  class Csv < Intrigue::Handler::Base

    def self.type
      "csv"
    end

    def process(result)

      return "Unable to process" unless result.respond_to? export_csv

      File.open("#{result.name}.csv", "a") do |file|
        _lock(file) do
          file.puts(result.export_csv)  # write it out
        end
      end

    end

  end
end
end
