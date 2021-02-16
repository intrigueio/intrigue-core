module Intrigue    
module Issue
    class BaseIssue
    
      def self.inherited(base)
        Intrigue::Issue::IssueFactory.register(base)
        super
      end
    
      def self.export_hash
        generate({})
      end
    
      def self.export_json
        generate({}).to_json
      end
    end
end
end