module Intrigue
module Report
module Handler
  class Base

    def self.inherited(base)
      ReportFactory.register(base)
    end
    
  end
end
end
end
