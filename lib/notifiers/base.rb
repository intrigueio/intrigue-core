module Intrigue
module Notifier
  class Base

    def self.inherited(base)
      NotifierFactory.register(base)
    end

    def notify(message)
      raise "This method must be overridden"
    end

    private

      def _get_notifier_config(key)
        begin
          Intrigue::System::Config.config["intigue_notifiers"][self.class.metadata[:name]][key]
        rescue NoMethodError => e
          puts "Error, invalid config key requested (#{key}) for #{self.class.metadata[:name]}: #{e}"
        end
      end

  end
end
end
