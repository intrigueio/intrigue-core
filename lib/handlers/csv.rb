module Intrigue
module Handler
  class Csv < Intrigue::Handler::Base

    def self.type
      "csv"
    end

    def process(result, options)
      begin
        csv_file = "#{$intrigue_basedir}/results/results.csv"
        File.open(csv_file, "a+") do |file|
          file.flock(File::LOCK_EX)
          file.puts( result.export_csv)  # write it out
        end
      rescue Errno::EACCES
        return false
      end
    true
    end

  end
end
end
