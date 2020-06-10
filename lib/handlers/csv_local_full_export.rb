module Intrigue
module Handler
  class CsvLocalFileExport < Intrigue::Handler::Base

    def self.metadata
      {
        :name => "csv_local_full_export",
        :pretty_name => "Export to Local File (CSV in ./tmp)",
        :type => "export"
      }
    end

    def perform(result_type, result_id, prefix_name=nil)
      result = eval(result_type).first(id: result_id)
      puts "Local CSV Handler called on #{result_type}: #{result.name}"

      # write to a tempfile first
      timestamp = "#{Time.now.strftime("%Y%m%d%H%M%S")}"
      file = File.open("#{$intrigue_basedir}/tmp/#{result.name}.entities.#{timestamp}.csv", "a")
      
      result.entities.paged_each(rows_per_fetch: 500) do |e|
        file.write("#{e.export_csv}\n")
      end

      file.close 
    end

  end
end
end
