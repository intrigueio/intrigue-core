module Intrigue
module Handler
  class ElasticsearchBulk < Intrigue::Handler::Base

    def self.type
      "elasticsearch_bulk"
    end

    def process(task_result, options)
      # Write it out
      shortname = "#{task_result.task_name}"
      File.open("#{$intrigue_basedir}/results/#{shortname}.bulk", "a") do |file|
        _lock(file) do
          file.write("{ \"index\" : { \"_index\" : \"task_results\", \"_type\" : \"#{task_result.task_name}\", \"_id\" : \"#{task_result.id}\" } }\n")
          file.write(task_result.export_hash.to_json)
          file.write "\n"
        end
      end
    end
  end
end
end
