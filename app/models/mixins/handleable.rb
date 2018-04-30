module Intrigue
module Model
module Mixins
module Handleable

  def handle(prefix=nil)
    self.handlers.each do |handler_type|
      handler = Intrigue::HandlerFactory.create_by_type(handler_type)
      handler.class.perform_async(self.class, self.id, prefix)
    end
  end

  def handle(handler_type, prefix=nil)
    handler = Intrigue::HandlerFactory.create_by_type(handler_type)
    handler.class.perform_async(self.class, self.id, prefix)
  end

end
end
end
end
