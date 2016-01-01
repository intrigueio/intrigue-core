module Intrigue
module Handler
  class Json < Intrigue::Handler::Base

    def self.type
      "json"
    end

    def process(task_result, options)

      ### THIS IS A HACK TO GENERATE A FILENAME ... think this through a bit more
      shortname = "#{task_result.task_name}-#{task_result.base_entity.name.gsub("/","")}"

      # Write it out
      File.open("#{$intrigue_basedir}/results/#{shortname}.json", "w") do |file|
        file.write(JSON.pretty_generate(task_result.export_hash))
      end
    end

  end
end
end
