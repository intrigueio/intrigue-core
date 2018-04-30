module Intrigue
module Handler
  class Json < Intrigue::Handler::Base

    def self.type
      "json"
    end

    def perform(result_type, result_id, prefix_name=nil)
      result = eval(result_type).first(id: result_id)
      return "Unable to process" unless result.respond_to? export_json

      # Write it out
      File.open("#{$intrigue_basedir}/tmp/#{prefix_name}#{result.name}.json", "w") do |file|
        file.write(result.export_json)
      end
    end

  end
end
end
