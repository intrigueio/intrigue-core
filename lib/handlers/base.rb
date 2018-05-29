module Intrigue
module Handler
  class Base

    include Sidekiq::Worker
    sidekiq_options :queue => "app", :backtrace => true

    def self.inherited(base)
      HandlerFactory.register(base)
    end

    def perform(klass, id, prefix=nil)
      raise "This method must be overridden"
    end

    private

      def _get_handler_config(key)
        begin
          global_config = $global_config
          global_config.config["intrigue_handlers"][self.class.metadata[:name]][key]
        rescue NoMethodError => e
          puts "Error, invalid config key requested (#{key}) for #{self.class.metadata[:name]}: #{e}"
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
