module Intrigue
module Report
module Handler
  class Json < Intrigue::Report::Handler::Base

    def self.type
      "json" # XXX can we get this from self.class?
    end

    def generate(task_result, options)

      ### THIS IS A HACK TO GENERATE A FILENAME ... think this through a bit more
      shortname = "#{task_result.task_name}-#{task_result.entity.attributes["name"].gsub("/","")}"

      # Write it out
      File.open("#{$intrigue_basedir}/results/#{shortname}.json", "w+") do |file|
        file.flock(File::LOCK_EX)
        file.write(JSON.pretty_generate(JSON.parse(task_result.to_json)))
      end
    end

  end
end
end
end
