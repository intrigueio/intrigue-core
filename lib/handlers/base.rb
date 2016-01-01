module Intrigue
module Handler
  class Base

    def self.inherited(base)
      HandlerFactory.register(base)
    end

    private

      def _get_handler_config(key)
        begin
          $intrigue_config["handlers"][self.class.type][key]
        rescue NoMethodError => e
          puts "Error, invalid config key requested (#{key}) for #{type}: #{e}"
        end
      end

      def _lock(path)
        # We need to check the file exists before we lock it.
        if File.exist?(path)
          File.open(path).flock(File::LOCK_EX)
        end

        # Carry out the operations.
        yield

        # Unlock the file.
        File.open(path).flock(File::LOCK_UN)
      end
      
  end
end
end
