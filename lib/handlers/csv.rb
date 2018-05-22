module Intrigue
module Handler
  class Csv < Intrigue::Handler::Base

    def self.metadata
      {
        :name => "csv",
        :type => "export"
      }
    end


    def perform(result_type, result_id, prefix_name=nil)
      result = eval(result_type).first(id: result_id)
      return "Unable to process" unless result.respond_to? "export_csv"

      # write to a file bit by bit
      file = File.open("#{$intrigue_basedir}/tmp/#{result.name}.csv", "a")
      result.entities.paged_each(rows_per_fetch: 1000) do |e|
        file.puts("#{e.export_csv}\n")
        file.flush
      end

      file.close
    end

  end
end
end
