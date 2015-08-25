module Intrigue
module Handler
  class Csv < Intrigue::Handler::Base

    def self.type
      "csv" # XXX can we get this from self.class?
    end

    def process(result, options)

      return "Unable to handle #{result}" unless result.kind_of? Intrigue::Model::TaskResult

      begin
        csv_file = "#{$intrigue_basedir}/results/results.csv"
        # Create the file if it doesn't exist
        File.create csv_file unless File.exist? csv_file
        # Append to it
        File.open(csv_file, "a+") do |file|
          file.flock(File::LOCK_EX)
          # Create outstring
          outstring = result.export_csv
          # write it out
          file.puts(outstring)
        end
      rescue Errno::EACCES
        false
      end
    true
    end

  end
end
end
