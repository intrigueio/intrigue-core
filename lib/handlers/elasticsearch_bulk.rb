module Intrigue
module Handler
  class ElasticsearchBulk < Intrigue::Handler::Base

    def self.type
      "elasticsearch_bulk"
    end

    def process(result)

      return "Unable to process" unless result.respond_to? export_json

      # Write it out
      shortname = "#{result.name}"
      File.open("#{_export_file_path(result)}.bulk", "a") do |file|
        _lock(file) do
          file.write("{ \"index\" : { \"_index\" : \"results\", \"_type\" : \"#{result.task_name}\", \"_id\" : \"#{result.id}\" } }\n")
          file.write(result.export_json)
          file.write "\n"
        end
      end
    end
  end
end
end
