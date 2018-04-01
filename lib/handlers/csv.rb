module Intrigue
module Handler
  class Csv < Intrigue::Handler::Base

    def self.type
      "csv"
    end

    def process(result)

      File.open("#{$intrigue_basedir}/tmp/#{result.name}.csv", "a") do |file|
        _lock(file) do
          file.puts(result.export_csv)  # write it out
        end
      end

    end

  end
end
end
