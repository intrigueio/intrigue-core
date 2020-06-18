module Intrigue
  module Model
    class GlobalEntity < Sequel::Model
      plugin :validation_helpers
      plugin :timestamps

      self.raise_on_save_failure = false

      def validate
        super
        validates_unique([:namespace, :type, :name])
      end

      def self.load_global_namespace(data)
        (data["entities"] || []).each do |x|
          Intrigue::Model::GlobalEntity.update_or_create(:name => x["name"], :type => x["type"], :namespace => x["namespace"])
        end
      end

    end
  end
end
