module Intrigue
  module Model
    class ScanResult
      include DataMapper::Resource

      belongs_to :base_entity, 'Intrigue::Model::Entity'
      belongs_to :logger, 'Intrigue::Model::Logger'
      belongs_to :project, :default => lambda { |r, p| Intrigue::Model::Project.current_project }

      has n, :task_results, :through => Resource, :constraint => :destroy
      has n, :entities, :through => Resource, :constraint => :destroy

      property :id, Serial
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

      def self.all_in_current_project
        all(:project_id => 1)
      end

      def start
        ###
        # Create the Scanner
        ###
        if @scan_type == "discovery"
          scan = Intrigue::Scanner::DiscoveryScan.new
        elsif @scan_type == "dns_subdomain"
          scan = Intrigue::Scanner::DnsSubdomainScan.new
        else
          raise "Unknown scan type: #{@scan_type}"
        end

        # Kick off the scan
        scan.class.perform_async @id
      end

      def add_task_result(task_result)
        @task_results << task_result
        save
      true
      end

      def add_entity(entity)
        return false if has_entity? entity
        attribute_set(:entity_count, @entity_count + 1)

        entity.scan_results << self
        entity.save

        self.entities << entity
        save
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
          "name" => @name,
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
          "log" => self.logger.full_log
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

    end
  end
end
