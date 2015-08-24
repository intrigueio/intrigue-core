module Intrigue
module Report
module Handler
  class Csv < Intrigue::Report::Handler::Base

    def self.type
      "csv" # XXX can we get this from self.class?
    end

    def generate(task_result, options)
      begin
        csv_file = "#{$intrigue_basedir}/results/results.csv"
        # Create the file if it doesn't exist
        File.create csv_file unless File.exist? csv_file
        # Append to it
        File.open(csv_file, "a+") do |file|
          file.flock(File::LOCK_EX)
          # Create outstring
          outstring = "#{task_result.task_name},#{task_result.entity.attributes["name"]},#{task_result.entities.map{|x| x.type + "#" + x.attributes["name"] }.join(";")}\n"
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
end
