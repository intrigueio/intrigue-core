module Intrigue
module Handler
  class Csv < Intrigue::Handler::Base

    def self.type
      "csv"
    end

    def process(result, options)

      return "Unable to handle #{result}" unless result.kind_of? Intrigue::Model::TaskResult

      begin
        csv_file = "#{$intrigue_basedir}/results/results.csv"
        File.open(csv_file, "a+") do |file|
          file.flock(File::LOCK_EX)
          # Create outstring
          outstring = result.export_csv
          # write it out
          file.puts(outstring)
        end
      rescue Errno::EACCES
        return false
      end

    true
    end

  end
end
end
