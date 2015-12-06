module Intrigue
module Handler
  class JsonArray < Intrigue::Handler::Base

    def self.type
      "json_array"
    end

    def process(task_result, options)
      # Write it out
      File.open("#{$intrigue_basedir}/results/results.json", "a+") do |file|
        file.flock(File::LOCK_EX)
        results = JSON.parse file.read
        results << task_result.export_hash
        file.puts(JSON.pretty_generate(results))
      end
    end

  end
end
end
