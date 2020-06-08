module Intrigue
module Handler
  class ElasticsearchBulk < Intrigue::Handler::Base

    def self.metadata
      {
        :name => "elasticsearch_bulk",
        :pretty_name => "Export to ElasticSearch (BULK JSON)",
        :type => "export"
      }
    end

    def perform(result_type, result_id, prefix_name=nil)
      result = eval(result_type).first(id: result_id)
      return "Unable to process" unless result.respond_to? "export_json"

      # Write it out
      File.open("#{$intrigue_basedir}/public/#{prefix_name}#{result.name}.bulk", "a") do |file|
        file.write("{ \"index\" : { \"_index\" : \"results\", \"_type\" : \"task_result\", \"_id\" : \"#{result.id}\" } }\n")
        file.write(result.export_json)
        file.write "\n"
      end
    end

  end
end
end
