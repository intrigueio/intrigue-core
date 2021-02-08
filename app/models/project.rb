module Intrigue
module Core
module Model
  class Project < Sequel::Model
    plugin :validation_helpers
    plugin :serialization, :json, :options, :handlers, :allowed_namespaces
    plugin :timestamps

    self.raise_on_save_failure = true

    one_to_many :logger
    one_to_many :alias_groups
    one_to_many :task_results
    one_to_many :scan_results
    one_to_many :issues

    include Intrigue::Core::ModelMixins::Handleable
    include Intrigue::Core::System::DnsHelpers

    def validate
      super
      validates_unique(:name)
    end

    def delete!
      self.scan_results.each{|x| x.delete }
      self.task_results.each{|x| x.delete }
      self.alias_groups.each{ |x| x.delete}
      self.issues.each{|x| x.delete }
      self.entities.each{ |x| x.remove_all_task_results}
      self.entities.each{|x| x.delete }
      self.delete
    true 
    end

    def issues
      Intrigue::Core::Model::Issue.scope_by_project(self.name) || []
    end

    def entities
      Intrigue::Core::Model::Entity.scope_by_project(self.name) || []
    end

    def seeds
      Intrigue::Core::Model::Entity.scope_by_project(self.name).where(seed: true)
    end

    def seed_entity?(type_string, entity_name)
      return true if seeds.first(name: entity_name, type: "Intrigue::Entity::#{type_string}")
    false
    end

    def to_v1_api_hash(full_details=false)
      out = {
        :id => self.id,
        :uuid => self.uuid,
        :name => "#{self.name}",
        :created_at => "#{self.created_at}",
        :use_standard_exceptions => self.use_standard_exceptions,
        :allowed_namespaces => self.allowed_namespaces,
        :allow_reenrich => self.allow_reenrich,
        :vulnerability_checks_enabled => self.vulnerability_checks_enabled,
        :cancelled => self.cancelled,
        :seed_count => seeds.count,
        :entity_count => self.entities.count,
        :issue_count => self.issues.count
      }

      if full_details
        out.merge!(
          {}  
        )
      end

    out
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
      export_hash.merge("generated_at" => "#{Time.now.utc}").to_json
    end

    def export_entities_csv

      output_string = ""
      self.entities.paged_each do |e|
        output_string << e.export_csv << "\n"
      end

    output_string
    end

    def export_csv_by_type(type_string)
      Intrigue::Core::Model::Entity.scope_by_project_and_type(self.name, type_string).map { |e| e.export_csv }.join("\n")
    end

    def export_applications_csv
      headings = ["IpAddress","Uri","Enriched","Title","Fingerprint","Network", "Geo"]
      static_heading_count = 6

      entities = Intrigue::Core::Model::Entity.scope_by_project_and_type(self.name, "Intrigue::Entity::Uri")
      
      # this is pretty hacky... take the content of the first entity that has content
      # and use the keys of that field as additional headings. See below, 
      # we'll ask every application for this same set of fields
      #content_entities = entities.select{|x| x.get_detail("content").kind_of?(Array) and x.get_detail("content").count > 0 }
      # puts "Got content entities: #{content_entities.count} #{content_entities.first}"
      content_entity_headings = entities.map{ |x| x.get_detail("content").map{|h| h["name"]} if x.get_detail("content") }.flatten.uniq.compact
      STDOUT.flush

      if content_entity_headings.count > 0
        headings.concat(content_entity_headings)
      end

      out = headings.join(", ") 
      out << "\n"

      entities.sort_by{|e| e.name }.each do |x|

        # Resolve the host
        host_id = x.get_detail("host_id")
        host = Intrigue::Core::Model::Entity.scope_by_project(self.name).first(:id => host_id)
        if host
          out << "#{host.name.gsub(",",";")}, "
        else
          out << "[Unknown], "
        end

        out << "#{x.name.gsub(",",";")}, "

        #products = x.get_detail("products")
        #product_string = products.map{|p| p["matched"] }.compact.join("; ") if products
        #out << "#{product_string}" if product_string

        out << "#{x.enriched}, "

        page_title = x.get_detail("title")
        page_title_string = page_title.gsub(",","") if page_title
        out << "#{page_title_string}, "

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
        out << ", "

        ###
        ### Network Name
        ###
        net_name = x.get_detail("net_name")
        out << "#{net_name}".gsub(","," ")
        out << ", "

        ###
        ### Geography
        ###
        net_geo = x.get_detail("net_geo")
        out << "#{net_geo}, "

        ###
        ### Alt Names
        ###
        alt_names = x.get_detail("alt_names")
        out << "#{(alt_names||[]).join(" | ")}, "


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

    def globally_traversable_entity?(entity_name, type_string)
        
      out = true  # allow traverse, until we have something that we can verify

      # now form the query, taking into acount the filter if we can
      found_entity = Intrigue::Core::Model::GlobalEntity.exists?(type_string, entity_name)

      # now lets check if we have an allowance for it
      if found_entity

        out = false # we found it, default is now no-traverse ... unless... 

        # we have a matching namespace
        (self.allowed_namespaces || []).each do |namespace|
          if found_entity.namespace.downcase == namespace.downcase # Good! 
            return true # boom match, return immediately
          end
        end

      end

    out 
    end

    ###
    ### Use this when you want to scope in stuff, but generally prefer 'traversable_entity?'
    ###
    def allow_list_entity?(entity)      
      our_scope_verification_list = entity.scope_verification_list

      svt = Intrigue::Core::Model::GlobalEntity.scope_verification_types

      our_scope_verification_list.each do |h|

        type_string = h[:type_string]
        entity_name = h[:name]

        # skip anything else thats not verifiable!!
        next unless svt.include? type_string
        
        # Check standard exceptions (hardcoded list) first if we
        #  show up here (and we werent' a seed), we should skip
        return false if use_standard_exceptions && 
          standard_no_traverse?(entity_name, type_string)

        # if it's an explicit seed, it's whitelisted 
        return true if seed_entity?(type_string,entity_name)

        # if we don't have a list, safe to return false now, otherwise proceed to 
        # additional exceptions which are provided as an attribute on the object
        unless globally_traversable_entity?(entity_name, type_string)
          return false 
        end
        
      end 

    ###
    # returning false because it wasnt explicitly allowed
    ###
    false
    end

    ###
    ### Use this when you wan to scope out stuff based on rules or global intel
    ###
    def deny_list_entity?(entity)
      
      our_scope_verification_list = entity.scope_verification_list

      svt = Intrigue::Core::Model::GlobalEntity.scope_verification_types

      our_scope_verification_list.each do |h|

        type_string = h[:type_string]
        entity_name = h[:name]

        # skip anything else thats not verifiable!!
        next unless svt.include? "#{type_string}"

        # Check standard exceptions (hardcoded list) first if we
        #  show up here (and we werent' a seed), we should skip
        return true if use_standard_exceptions && 
          standard_no_traverse?(entity_name, type_string)

        # if it's an explicit seed, it's not blacklisted 
        return false if seed_entity?(type_string,entity_name)

        # now check the global intel 
        # if we don't have a list, safe to return false now, otherwise proceed to 
        # additional exceptions which are provided as an attribute on the object
        unless globally_traversable_entity?(entity_name, type_string)
          return true 
        end
      
      end

    ###
    # returning false because it wasnt explicitly disallowed
    ###
    false
    end

    # Method gives us a true/false, depending on whether the entity is in an
    # exception list. Currently only used on project, but could be included
    # in task_result or scan_result. Note that they'd need the "additional_exception_list"
    # to be populated (automated by bootstrap)
    ###
    ### DEFAULTS TO FALSE!!! WHITELIST APPROACH
    ###
    def traversable_entity?(entity)

      return true if allow_list_entity?(entity)
      return false if deny_list_entity?(entity)
    
    # otherwise, permissive
    true
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
end