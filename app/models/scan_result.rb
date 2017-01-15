module Intrigue
  module Model
    class ScanResult < Sequel::Model
      plugin :validation_helpers

      #set_allowed_columns :project_id, :logger_id, :base_entity_id, :name, :depth, :handlers, :strategy, :filter_strings

      many_to_one :logger
      many_to_one :project
      one_to_many :task_results
      many_to_one :base_entity, :class => :'Intrigue::Model::Entity', :key => :base_entity_id

      def self.scope_by_project(project_name)
        named_project_id = Intrigue::Model::Project.first(:name => project_name).id
        where(:project_id => named_project_id)
      end

      def validate
        super
        #validates_unique([:name, :project_id, :depth])
      end

      def log
        logger.full_log
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
          "id" => id,
          "name" =>  URI.escape(name),
          "depth" => depth,
          "complete" => complete,
          "strategy" => strategy,
          "timestamp_start" => timestamp_start,
          "timestamp_end" => timestamp_end,
          "filter_strings" => filter_strings,
          "base_entity" => self.base_entity.export_hash,
          "task_results" => self.task_results.map{|t| t.export_hash },
          "entities" => self.entities.map {|e| e.export_hash },
          "options" => options,
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
