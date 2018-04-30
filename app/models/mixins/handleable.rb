module Intrigue
module Model
module Mixins
module Handleable

      def handle(prefix=nil)
        handled = []
        self.handlers.each do |handler_type|
          handler = Intrigue::HandlerFactory.create_by_type(handler_type)
          handled << handler.perform(self.class, self.id, prefix)
        end
      handled
      end

      def handle(handler_type, prefix=nil)
        handler = Intrigue::HandlerFactory.create_by_type(handler_type)
        handler.perform(self.class, self.id, prefix)
      end

end
end
end
end
