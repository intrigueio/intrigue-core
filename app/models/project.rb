module Intrigue
  module Model
    class Project < Sequel::Model
      plugin :validation_helpers
      plugin :serialization, :json, :options, :handlers, :additional_exception_list

      one_to_many :logger
      one_to_many :task_results
      one_to_many :scan_results
      one_to_many :issues

      include Intrigue::Model::Mixins::Handleable

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

      def seeds
        Intrigue::Model::Entity.scope_by_project(self.name).where(seed: true).all || [] 
      end

      def seed_entity?(entity_name, type_string)
        seeds.each do |s|
          return true if entity_name == s.name && type_string == s.type.to_s
        end
      false
      end

      def export_hash
        {
          :id => id,
          :name => "#{name}",
          :seeds => seeds,
          :entities => entities.map {|e| e.export_hash },
          :issues => issues.map {|i| i.export_hash }
        }
      end

      def export_json
        export_hash.merge("generated_at" => "#{DateTime.now}").to_json
      end

      def export_entities_csv

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
        headings = ["IpAddress","Uri","Enriched","Title","Fingerprint","Javascript"]
        static_heading_count = 6

        entities = Intrigue::Model::Entity.scope_by_project_and_type(self.name, "Intrigue::Entity::Uri")
        
        # this is pretty hacky... take the content of the first entity that has content
        # and use the keys of that field as additional headings. See below, 
        # we'll ask every application for this same set of fields
        #content_entities = entities.select{|x| x.get_detail("content").kind_of?(Array) and x.get_detail("content").count > 0 }
       # puts "Got content entities: #{content_entities.count} #{content_entities.first}"
        content_entity_headings = entities.map{ |x| x.get_detail("content").map{|h| h["name"]} if x.get_detail("content") }.flatten.uniq.compact
        puts "Got Headings: #{content_entity_headings}"
        STDOUT.flush

        if content_entity_headings.count > 0
          headings.concat(content_entity_headings)
        end

        out = headings.join(", ") 
        out << "\n"

        entities.sort_by{|e| e.name }.each do |x|

          # Resolve the host
          host_id = x.get_detail("host_id")
          host = Intrigue::Model::Entity.scope_by_project(self.name).first(:id => host_id)
          if host
            out << "#{host.name.gsub(",",";")},"
          else
            out << "[Unknown],"
          end

          out << "#{x.name.gsub(",",";")},"

          #products = x.get_detail("products")
          #product_string = products.map{|p| p["matched"] }.compact.join("; ") if products
          #out << "#{product_string}" if product_string

          out << "#{x.enriched},"

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

          js = x.get_detail("javascript")
          if js
            js.each do |f|
              temp = "#{f["library"]}"
              temp << " #{f["version"]}"
              temp << " | "
              out << temp.gsub(",",";")
            end
          end
          out << ","


          if content_entity_headings.count > 0
            # dynamically dump all config values in the correct orders
            content = x.get_detail("content")
            if content
              headings[static_heading_count..-1].each do |h|
                next unless h
                out << "#{content.select{|x| x["name"] == h if x  }.first["result"]}".gsub(",",";") << ","
              end
            end
          end

          out << "\n"
        end

      out
      end

      # Method gives us a true/false, depending on whether the entity is in an
      # exception list. Currently only used on project, but could be included
      # in task_result or scan_result. Note that they'd need the "additional_exception_list"
      # to be populated (automated by bootstrap)
      def exception_entity?(entity_name, type_string=nil, skip_regexes)

        # if it's a seed exception, can't be an exception.
        return false if seed_entity?(type_string,entity_name)

        # Check standard exceptions first
        return false if standard_exception?(entity_name, type_string, skip_regexes)

        # if we don't have a list, safe to return false now, otherwise proceed to additional exceptions
        # which are provided as an attribute on the object
        return false unless additional_exception_list

        # check additional exception strings
        out = false
        
        # first shorten up our list (speed it way up)
        check_list = additional_exception_list.select{ |x| entity_name.include? x }

        # then check each for a match 
        check_list.each do |x|
          # this needs a couple (3) cases:
          # 1) case where we're an EXACT match (ey.com)
          # 2) case where we're a subdomain of an exception domain (x.ey.com)
          # 3) case where we're a uri and should match an exception domain (https://ey.com)
          # none of these cases should match the case: jcpenney.com
          if (entity_name.downcase =~ /^#{Regexp.escape(x.downcase)}(:[0-9]*)?$/ ||
            entity_name.downcase =~ /^.*\.#{Regexp.escape(x.downcase)}(:[0-9]*)?$/ ||
            entity_name.downcase =~ /^https?:\/\/#{Regexp.escape(x.downcase)}(:[0-9]*)?$/)
            out = x
          end
        end

        #puts "Checking if #{entity_name} matches our no-traverse list: #{out}"

      out
      end

      # TODO - there must be a cleaner way? 
      def get_option(option_name)
        opt = options.detect{|h| h[option_name] } if options
        opt.each{|k,v| return v } if opt
      end

      # TODO ... move this into the issue model
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
