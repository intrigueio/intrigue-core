module Intrigue
  module Model
    class ScanResult
      include DataMapper::Resource

      belongs_to :base_entity, 'Intrigue::Model::Entity'
      belongs_to :logger, 'Intrigue::Model::Logger'
      belongs_to :project, :default => lambda { |r, p| Intrigue::Model::Project.first }

      has n, :task_results, :through => Resource, :constraint => :destroy
      has n, :entities, :through => Resource, :constraint => :destroy

      property :id, Serial, :key => true
      property :name, String
      property :depth, Integer
      property :scan_type, String
      property :options, Object, :default => []
      property :handlers, Object, :default => []
      property :complete, Boolean, :default => false

      property :timestamp_start, DateTime
      property :timestamp_end, DateTime

      property :entity_count, Integer, :default => 0
      property :filter_strings, Text, :default => ""

      def self.scope_by_project(name)
        all(:project => Intrigue::Model::Project.first(:name => name))
      end

      def log
        self.logger.full_log
      end

      def start
        ###
        # Create the Scanner
        ###
        if @scan_type == "discovery"
          scan = Intrigue::Scanner::DiscoveryScan.new
        elsif @scan_type == "dns_subdomain"
          scan = Intrigue::Scanner::DnsSubdomainScan.new
        elsif @scan_type == "quick_dns_subdomain"
          scan = Intrigue::Scanner::QuickDnsSubdomainScan.new
        elsif @scan_type == "survey_scan"
          scan = Intrigue::Scanner::SurveyScan.new
        else
          raise "Unknown scan type: #{@scan_type}"
        end

        # Kick off the scan
        scan.class.perform_async @id
      end

      def add_task_result(task_result)
        # Handle exceptions here since this may not be thread safe
        #  https://github.com/datamapper/dm-core/issues/286
        begin
          self.task_results << task_result
          save
        rescue Exception => e
          false
        end
      true
      end

      def add_entity(entity)
        return false if has_entity? entity

        # Handle exceptions here since this may not be thread safe
        #  https://github.com/datamapper/dm-core/issues/286
        begin
          attribute_set(:entity_count, @entity_count + 1)
          entity.scan_results << self
          entity.save
          self.entities << entity
          save
        rescue Exception => e
          false
        end
      true
      end

      # Matches based on type and the attribute "name"
      def has_entity? entity
        return true if (self.entities.select {|e| e.match? entity}).length > 0
      end

      ###
      ### Export!
      ###

      def export_hash
        {
          "id" => @id,
          "name" =>  URI.escape(@name),
          "scan_type" => @scan_type,
          "depth" => @depth,
          "complete" => @complete,
          "timestamp_start" => @timestamp_start,
          "timestamp_end" => @timestamp_end,
          "filter_strings" => @filter_strings,
          "base_entity" => self.base_entity.export_hash,
          "entity_count" => @entity_count,
          "task_results" => self.task_results.map{|t| t.export_hash },
          "entities" => self.entities.map {|e| e.export_hash },
          "options" => @options,
          "log" => log
        }
      end

      def export_json
        export_hash.to_json
      end

      def export_csv
        output_string = ""
        self.entities.each{ |x| output_string << x.export_csv << "\n" }
      output_string
      end

      def export_graph_csv
        output_string = ""
        # dump the entity name, all chilren entity names, and
        # remove both spaces and commas
        self.entities.each do |x|
          output_string << x.name.gsub(/[\,,\s]/,"") << ", " << "#{x.children.map{ |y| y.name.gsub(/[\,,\s]/,"") }.join(", ")}\n"
        end
      output_string
      end

      def export_graph_json

        # generate the nodes
        nodes = []
        # Add the base entity
        nodes << { :id => base_entity.id, :label => "#{base_entity.name}" }
        # And all the child entities
        nodes = self.entities.map{|x| {:id => x.id, :label => "#{x.name}"}  }
        # But make sure we only have one
        nodes.uniq! {|x| x[:id] }

        #
        # calculate edges from the base entity
        #
        #base_entity.children.each do |c|
          #puts "working on #{base_entity.to_s} => #{c.to_s}"
          #puts "DEBUG Child ID #{c.id} not found in " unless debug_node_ids.include? c.id
        #  edges << {"id" => edge_count, "source" => base_entity.id, "target" => c.id }
        #  edge_count += 1
        #end

        # calculate child edges
        edges = []
        edge_count = 1
        self.task_results.each do |t|
          t.entities.each do |e|
            edges << {"id" => edge_count, "source" => t.base_entity.id, "target" => e.id}

            # Hack, since it seems like our entities list doesn't contain everything.
            nodes << {:id => e.id, :label => "#{e.type}: #{e.name}"}
            nodes.uniq! {|x| x[:id]}

            edge_count += 1
          end
        end

        # dump the json
        { "nodes" => nodes, "edges" => edges }.to_json
      end

    end
  end
end
