module Intrigue
module Core
module ModelMixins
module Handleable

  def handle(handler_type, prefix=nil)
    handler = Intrigue::HandlerFactory.create_by_type(handler_type)
    handler.class.perform_async("#{self.class}", self.id, prefix)
  end

  def handle_synchronous(handler_type, prefix=nil)
    handler = Intrigue::HandlerFactory.create_by_type(handler_type)
    handler.perform("#{self.class}", self.id, prefix)
  end

  def handle_attached(prefix=nil)
    self.handlers.each do |handler_type|
      handler = Intrigue::HandlerFactory.create_by_type(handler_type)
      handler.class.perform_async("#{self.class}", self.id, prefix)
    end
  end

end
end
end
end
