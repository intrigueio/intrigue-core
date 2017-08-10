module Intrigue
  module Model
    class Project < Sequel::Model
      plugin :validation_helpers
      plugin :serialization, :json, :options, :handlers

      one_to_many :logger
      one_to_many :task_results
      one_to_many :scan_results

      def validate
        super
        validates_unique(:name)
      end

      def entities
        Intrigue::Model::Entity.where(
          :project_id => id,
          :hidden => false,
          :deleted => false)
      end

      def export_hash
        {
          :id => id,
          :name => "#{name}",
          :entities => entities.map {|e| e.export_hash } #,
          #:task_results => task_results.map {|t| t.export_hash },
          #:scan_results => scan_results.map {|s| s.export_hash }
        }
      end

      def export_json
        export_hash.to_json
      end

      def handle
        handled = []
        self.handlers.each do |handler_type|
          handler = Intrigue::HandlerFactory.create_by_type(handler_type)
          handled << handler.process(self)
        end
      handled
      end

      def handle(handler_type)
        handler = Intrigue::HandlerFactory.create_by_type(handler_type)
        handler.process(self)
      end

    end
  end
end
