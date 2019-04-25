module Intrigue
module Handler
  class Json < Intrigue::Handler::Base

    def self.metadata
      {
        :name => "json",
        :pretty_name => "Export JSON (/public)",
        :type => "export"
      }
    end

    def perform(result_type, result_id, prefix_name=nil)
      result = eval(result_type).first(id: result_id)
      raise "Unable to process" unless result.respond_to? "export_json"

      # write to a file bit by bit
      file = File.open("#{$intrigue_basedir}/public/#{result.name}.json", "a")
      result.entities.paged_each(rows_per_fetch: 1000) do |e|
        file.puts("#{e.export_json}\n")
        file.flush
      end
      file.close

    end

  end
end
end
