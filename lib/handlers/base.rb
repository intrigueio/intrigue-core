module Intrigue
module Handler
  class Base

    def self.inherited(base)
      HandlerFactory.register(base)
    end

    private

      def _export_file_path(result)
        "#{$intrigue_basedir}/results/#{result.name}_on_#{result.base_entity.name}"
      end


      def _get_handler_config(key)
        begin
          $intrigue_config["intrigue_handlers"][self.class.type][key]
        rescue NoMethodError => e
          puts "Error, invalid config key requested (#{key}) for #{type}: #{e}"
        end
      end

      def _lock(file)
   	      begin
            file.flock(File::LOCK_EX)
   	        yield
   	      ensure
   	        file.flock(File::LOCK_UN)
     	    end
     	end

  end
end
end
