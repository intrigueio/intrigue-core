module Intrigue
module Handler
  class Csv < Intrigue::Handler::Base

    def self.type
      "csv"
    end

    def process(task_result, options)
      filename = "#{$intrigue_basedir}/results/#{task_result.task_name}.csv"

      _lock(filename) do |file|
        File.open(filename, "a") do |file|
          file.puts(result.export_csv)  # write it out
        end
      end

    end

  end
end
end
