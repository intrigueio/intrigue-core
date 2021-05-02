module Intrigue
module Core
module Handler
  class WriteToFileCsv < Intrigue::Core::Handler::Base

    def self.metadata
      {
        :name => "write_to_file_csv",
        :pretty_name => "Write to File (CSV in ./tmp)",
        :type => "export"
      }
    end

    def perform(result_type, result_id, prefix_name=nil)
      result = eval(result_type).first(id: result_id)
      puts "Local CSV Handler called on #{result_type}: #{result.name}"

      # write to a tempfile first
      timestamp = "#{Time.now.utc.iso8601}"
      file = File.open("#{$intrigue_basedir}/tmp/#{result.name}.entities.#{timestamp}.csv", "a")

      result.entities.paged_each(rows_per_fetch: 500) do |e|
        file.write("#{e.export_csv}\n")
      end

      file.close
    end

  end
end
end
end