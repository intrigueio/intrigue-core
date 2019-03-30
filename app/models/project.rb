module Intrigue
  module Model
    class Project < Sequel::Model
      plugin :validation_helpers
        plugin :serialization, :json, :seeds, :options, :handlers, :additional_exception_list

      one_to_many :logger
      one_to_many :task_results
      one_to_many :scan_results
      one_to_many :issues
      #one_to_many :entities

      include Intrigue::Model::Mixins::Handleable
      include Intrigue::Model::Mixins::MatchExceptions

      def validate
        super
        validates_unique(:name)
      end

      def delete!
        self.scan_results.each{|x| x.delete }
        self.task_results.each{|x| x.delete }
        self.entities.each{|x| x.delete }
        self.delete
      end

      def entities
        Intrigue::Model::Entity.scope_by_project(self.name)
      end

      def seed_entity?(entity_name, type_string)

        if seeds
          seeds.each do |s|
            return true if entity_name == s["name"] && (type_string == s["type"] || type_string == "Intrigue::Entity#{s["type"]}")
          end
        end

      false
      end

      def export_hash
        {
          :id => id,
          :name => "#{name}",
          :seeds => seeds,
          :entities => entities.map {|e| e.export_hash }
          #:task_results => task_results.map {|t| t.export_hash }
          #:scan_results => scan_results.map {|s| s.export_hash }
        }
      end

      def export_json
        export_hash.merge("generated_at" => "#{DateTime.now}").to_json
      end

      def export_csv

        output_string = ""
        self.entities.paged_each do |e|
          output_string << e.export_csv << "\n"
        end

      output_string
      end

      def export_csv_by_type(type_string)
        Intrigue::Model::Entity.scope_by_project_and_type(self.name, type_string).map { |e| e.export_csv }.join("\n")
      end

      def export_applications_csv
        out = ""
        out << "IpAddress,Uri,Enriched,Title,Fingerprint,Javascript"

        Intrigue::Model::Entity.scope_by_project_and_type(self.name, "Intrigue::Entity::Uri").sort_by{|e| e.name }.each do |x|

          # Resolve the host
          host_id = x.get_detail("host_id")
          host = Intrigue::Model::Entity.scope_by_project(self.name).first(:id => host_id)
          if host
            out << "#{host.name},"
          else
            out << "[Unknown host],"
          end

          out << "#{x.name.gsub(",",";")},"

          #products = x.get_detail("products")
          #product_string = products.map{|p| p["matched"] }.compact.join("; ") if products
          #out << "#{product_string}" if product_string

          out << "#{.enriched},"

          page_title = x.get_detail("title")
          page_title_string = page_title.gsub(",","") if page_title
          out << "#{page_title_string},"


          fingerprint = x.get_detail("fingerprint")
          if fingerprint
            fingerprint.each do |f|
              temp = "#{f["vendor"]}"
              temp << " #{f["product"]}"
              temp << " #{f["version"]}" if f["version"]
              temp << " #{f["update"]}"  if f["update"]
              temp << " | "
              out << temp.gsub(",",";")
            end
          end
          out << ","

          fingerprint = x.get_detail("javascript")
          if fingerprint
            fingerprint.each do |f|
              temp = "#{f["library"]}"
              temp << " #{f["version"]}"
              temp << " | "
              out << temp.gsub(",",";")
            end
          end

          out << "\n"
        end

      out
      end


       def export_issues_csv
        out = ""
        out << "Name,Type,Status,Severity,Description\n"

        self.issues.sort_by{|i| i.severity }.each do |i|
          out << "#{i.name.gsub(","," ")}, #{i.type}, #{i.status}, #{i.severity}, #{i.description.gsub(","," ")}\n"
        end

      out
      end

    end
  end
end
