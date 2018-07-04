module Intrigue
module Ident
module Check
class Base

  def self.inherited(base)
    CheckFactory.register(base)
  end

end
end
end
end
