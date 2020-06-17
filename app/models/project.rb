module Intrigue
  module Model
    class Project < Sequel::Model
      plugin :validation_helpers
      plugin :serialization, :json, :options, :handlers, :allowed_namespaces
      plugin :timestamps

      one_to_many :logger
      one_to_many :task_results
      one_to_many :scan_results
      one_to_many :issues

      include Intrigue::Model::Mixins::Handleable
      include Intrigue::System::DnsHelpers

      def validate
        super
        validates_unique(:name)
      end

      def delete!
        self.scan_results.each{|x| x.delete }
        self.task_results.each{|x| x.delete }
        self.entities.each{|x| x.delete }
        self.issues.each{|x| x.delete }
        self.delete
      end

      def issues
        Intrigue::Model::Issue.scope_by_project(self.name) || []
      end

      def entities
        Intrigue::Model::Entity.scope_by_project(self.name) || []
      end

      def seeds
        Intrigue::Model::Entity.scope_by_project(self.name).where(seed: true).all || [] 
      end

      def seed_entity?(type_string, entity_name)
        seeds.compact.each do |s|
          return true if s.match_entity_string?(type_string, entity_name)
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

      def globally_traversable_entity?(entity_type, entity_name)
         
        # by default things are not traversable
        out = false

        # first check to see if we know about this exact entity (type matters too)
        puts "Looking for global entity: #{entity_type} #{entity_name}"
        global_entity = Intrigue::Model::GlobalEntity.first(:name => entity_name, :type => entity_type)

        # If we know it exists, is it in our project (cool) or someone else (no traverse!)
        if global_entity
          puts "Global entity found: #{entity_type} #{entity_name}!"
          
          # we need to have a namespace to validate against
          if self.allowed_namespaces
            self.allowed_namespaces.each do |namespace|
              # if the entity's' namespace matches one of ours, we're good!
              if global_entity.namespace.downcase == namespace.downcase 
                puts "Matches our namespace!"
                return true # we can immediately return 
              end
            end
          else
            puts "No allowed namespaces, and this is a claimed entity but not a seed!"
            return false
          end

        else 
          puts "No Global entity found, trying harder!"
        end

        # okay so if we made it this far, we may or may not have a matching entiy, so now 
        # we need to find if it matches based on regex... since entities can have a couple
        # different forms (uri, dns_record, domain, etc)

        # then check each for a match 
        found_entity = nil

        ## Okay let's get smart by getting down to the smallest searchable unit first
        searchable_name = nil
                
        if entity_type == "Domain"
          # this should have gotten caught above... 
          searchable_name = parse_domain_name(entity_name)
        elsif entity_type == "DnsRecord"  
          searchable_name = parse_domain_name(entity_name)
        elsif entity_type == "EmailAddress"  
          searchable_name = parse_domain_name(entity_name.split("@").last)
        elsif entity_type == "Nameserver"  
          searchable_name = parse_domain_name(entity_name)
        elsif entity_type == "Uri"
          searchable_name = parse_domain_name(URI.parse(entity_name).host)
        end

        # now form the query, taking into acount the filter if we can
        if searchable_name
          found_entity = Intrigue::Model::GlobalEntity.first(:type => "Domain", :name => searchable_name)
        else
          global_entities = Intrigue::Model::GlobalEntity.all

          global_entities.each do |ge|
            # this needs a couple (3) cases:
            # 1) case where we're an EXACT match (ey.com)
            # 2) case where we're a subdomain of an exception domain (x.ey.com)
            # 3) case where we're a uri and should match an exception domain (https://ey.com)
            # none of these cases should match the case: jcpenney.com
            if (entity_name.downcase =~ /^#{Regexp.escape(ge.name.downcase)}(:[0-9]*)?$/ ||
              entity_name.downcase =~ /^.*\.#{Regexp.escape(ge.name.downcase)}(:[0-9]*)?$/ ||
              entity_name.downcase =~ /^https?:\/\/#{Regexp.escape(ge.name.downcase)}(:[0-9]*)?$/)
              
              #okay we found it... now we need to check if it's an allowed project
              found_entity = ge
            end
          end
        end

      if found_entity && !self.allowed_namespaces.empty? # now lets check if we have an allowance for it

         (self.allowed_namespaces || []).each do |namespace|
          if found_entity.namespace.downcase == namespace.downcase # Good! 
            return true 
          end
        end

        out = false
      else # we never found it or we don't care (no namespaces)! 
        out = true 
      end

      #puts "Result for: #{entity_type} #{entity_name} in project #{project.name}: #{out}" 

      out 
      end


      ###
      ### Use this when you wan to scope in stuff 
      ###
      def allow_list_entity?(type_string, entity_name)
        
        # if it's an explicit seed, it's whitelisted 
        return true if seed_entity?(type_string,entity_name)

        ### CHECK OUR SEED ENTITIES TO SEE IF THE TEXT MATCHES A DOMAIN
        ######################################################
        # if it matches an explicit seed pattern, it's always traversable
        scope_check_entity_types = [
          "Intrigue::Entity::DnsRecord",
          "Intrigue::Entity::Domain",
          "Intrigue::Entity::EmailAddress",
          "Intrigue::Entity::Organization",
          "Intrigue::Entity::Nameserver",
          "Intrigue::Entity::Uri" 
        ]

        # skip anything else thats not verifiable!!
        return false unless scope_check_entity_types.include? "Intrigue::Entity::#{type_string}"

        seeds.each do |s| 
          if entity_name =~ /[\.\s\@]#{Regexp.escape(s.name)}/i
            return true # matches a seed pattern, it's whitelisted
          end
        end
      
        # Check standard exceptions (hardcoded list) first if we
        #  show up here (and we werent' a seed), we should skip
        if use_standard_exceptions
          if standard_no_traverse?(entity_name, type_string)
            #puts 'Matched a standard exception, not whitelisted'
            return false 
          end
        end

        # now check the global intel 
        verifiable_entity_types = ["DnsRecord", "Domain", "EmailAddress", "NameServer" "Uri"]
        if verifiable_entity_types.include? type_string
          # if we don't have a list, safe to return false now, otherwise proceed to 
          # additional exceptions which are provided as an attribute on the object
          unless globally_traversable_entity?(type_string, entity_name)
            puts 'Global intel says not traversable, returning false'
            return false 
          end
        end
        
      ###
      # Defaulting to not traversable (Whitelist approach!)
      ###
      false
      end

      ###
      ### Use this when you wan to scope out stuff based on rules or global intel
      ###
      def deny_list_entity?(type_string, entity_name)

        # if it's an explicit seed, it's not blacklisted 
        return false if seed_entity?(type_string,entity_name)

        ### CHECK OUR SEED ENTITIES TO SEE IF THE TEXT MATCHES A DOMAIN
        ######################################################
        # if it matches an explicit seed pattern
        scope_check_entity_types = [
          "Intrigue::Entity::DnsRecord",
          "Intrigue::Entity::Domain",
          "Intrigue::Entity::EmailAddress",
          "Intrigue::Entity::Organization",
          "Intrigue::Entity::Nameserver",
          "Intrigue::Entity::Uri" 
        ]

        # not blacklisted if we're not one of the check types
        return false unless scope_check_entity_types.include? "Intrigue::Entity::#{type_string}"

        seeds.each do |s|
          if entity_name =~ /[\.\s\@]#{Regexp.escape(s.name)}/i
            return false # not blacklisted if we're matching a seed derivative
          end
        end
      
        # Check standard exceptions (hardcoded list) first if we 
        # show up here (and we werent' a seed), we should skip
        if use_standard_exceptions
          if standard_no_traverse?(entity_name, type_string)
            return true  # matched a blacklist 
          end
        end

        # now check the global intel 
        verifiable_entity_types = ["DnsRecord", "Domain", "EmailAddress", "NameServer" "Uri"]
        if verifiable_entity_types.include? type_string
          # if we don't have a list, safe to return false now, otherwise proceed to 
          # additional exceptions which are provided as an attribute on the object
          if !globally_traversable_entity?(type_string, entity_name)
            puts 'Global intel says not traversable so we are blacklisted, returning true'
            return true 
          end
        end
        
      ###
      # we made it this far, not blacklisted!
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
      def traversable_entity?(type_string, entity_name)
        return true if allow_list_entity?(type_string, entity_name)
        return false if deny_list_entity?(type_string, entity_name)
      # otherwise, perimissive
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
