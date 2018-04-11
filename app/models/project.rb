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

      def export_csv
        out = ""

        out << "Type,Name,Alias Group,Details\n"
        self.entities.sort_by{|e| e.to_s }.each do |x|
          alias_string = x.alias_group.id if x.alias_group
          out << "#{x.type_string},#{x.name},#{alias_string},#{x.detail_string}\n"
        end

      out
      end

      def export_applications_csv
        out = ""
        out << "IpAddress,Uri,ServerFingerprint,AppFingerprint,IncludeFingerprint\n"

        self.entities.sort_by{|e| e.to_s }.each do |x|
          next unless x.kind_of? Intrigue::Entity::Uri

          # Resolve the host
          host_id = x.get_detail("host_id")
          host = Intrigue::Model::Entity.first(:id => host_id)
          if host
            out << "#{host.name},"
          else
            out << "[Unknown host],"
          end

          out << "#{x.name},"

          #products = x.get_detail("products")
          #product_string = products.map{|p| p["matched"] }.compact.join("; ") if products
          #out << "#{product_string}" if product_string

          server_fingerprint = x.get_detail("server_fingerprint")
          server_fingerprint_string = server_fingerprint.join("; ") if server_fingerprint
          out << "#{server_fingerprint_string},"

          app_fingerprint = x.get_detail("app_fingerprint")
          app_fingerprint_string = app_fingerprint.join("; ") if app_fingerprint
          out << "#{app_fingerprint_string},"

          include_fingerprint = x.get_detail("include_fingerprint")
          include_fingerprint_string = include_fingerprint.join("; ") if include_fingerprint
          out << "#{include_fingerprint_string}\n"

        end

      out
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
