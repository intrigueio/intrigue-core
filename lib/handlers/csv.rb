module Intrigue
module Handler
  class Csv < Intrigue::Handler::Base

    def self.type
      "csv"
    end

    def process(task_result, options)
      shortname = "#{task_result.task_name}"
      File.open("#{$intrigue_basedir}/results/#{shortname}.csv", "a") do |file|
        _lock(file) do
          file.puts(task_result.export_csv)  # write it out
        end
      end

    end

  end
end
end
