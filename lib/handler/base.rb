module Intrigue
module Handler
  class Base

    def self.inherited(base)
      HandlerFactory.register(base)
    end

  end
end
end
