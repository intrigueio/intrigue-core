module Intrigue
  module Model
    class ScanResult
      include DataMapper::Resource

      belongs_to :logger, 'Intrigue::Model::Logger'

      belongs_to :project, :default => lambda { |r, p| Intrigue::Model::Project.first }
      property :project_id, Integer, :index => true

      belongs_to :base_entity, 'Intrigue::Model::Entity'
      property :base_entity_id, Integer, :index => true

      has n, :task_results, :through => Resource

      property :id, Serial, :key => true
      property :name, String, :length => 200
      property :depth, Integer
      property :handlers, Object, :default => []
      property :complete, Boolean, :default => false
      property :strategy, String, :default => "default"
      property :depth, Integer, :default => 2
      property :filter_strings, Text, :default => ""

      def self.scope_by_project(project_name)
        all(:project => Intrigue::Model::Project.first(:name => project_name))
      end

      def log
        self.logger.full_log
      end

      # kick off the first task run, and this will kick off recursion based on depth & strategy
      def start
        task_results.first.start
      end

      def add_task_result(task_result)
        # Handle exceptions here since this may not be thread safe
        #  https://github.com/datamapper/dm-core/issues/286
        begin
          task_results << task_result
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
          entities.push entity
          save
        rescue Exception => e
          false
        end
      true
      end

      # Matches based on type and the attribute "name"
      def has_entity? entity
        return true if (entities.select {|e| e.match? entity}).length > 0
      end

      def entities
        entities=[]
        task_results.each {|x| x.entities.each {|e| entities << e } }
      entities
      end


      # just calculate it vs storing another property
      def entity_count
        entities.count
      end

      # just calculate it vs storing another property
      def timestamp_start
        return task_results.first.timestamp_start if task_results.first
      nil
      end

      # just calculate it vs storing another property
      def timestamp_end
        return task_results.last.timestamp_end if complete
      nil
      end

      ###
      ### Export!
      ###

      def export_hash
        {
          "id" => @id,
          "name" =>  URI.escape(@name),
          "depth" => @depth,
          "complete" => @complete,
          "strategy" => @strategy,
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
        nodes << { :id => self.base_entity.id, :label => "#{self.base_entity.name}" }
        # And all the child entities
        nodes.concat self.entities.map{|x| {:id => x.id, :label => "#{x.name}"}  }
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
