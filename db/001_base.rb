Sequel.migration do
  change do
    create_table :entities do
      primary_key :id
      foreign_key :project_id, :null => false
      foreign_key :task_result_id, :null => true
      String :type
      String :name, :size => 400
      String :details, :text => true

      FalseClass :secondary
    end

    create_table :entities_task_results do
      primary_key :id
      Integer :entity_id
      Integer :task_result_id
    end

    create_table :alias_mappings do
      primary_key :id

      Integer :source_id
      Integer :target_id
    end

    create_table :loggers do
      primary_key :id
      foreign_key :project_id, :null => false
      foreign_key :task_result_id, :null => true
      foreign_key :scan_result_id, :null => true

      String :full_log, :text => true
    end

    create_table :projects do
      primary_key :id

      String :name, :size => 400
      String :graph_json, :text => true
      DateTime :graph_generated_at
      FalseClass :graph_generation_in_progress
    end

    create_table :scan_results do
      primary_key :id
      foreign_key :project_id, :null => false
      foreign_key :logger_id, :null => false
      foreign_key :base_entity_id, :null => false

      String :name, :size => 400
      Integer :depth
      String :handlers
      FalseClass :complete
      String :strategy
      String :filter_strings

      # MIGRATE ME
      # DONE has n, :task_results, :through => Resource
      # END MIGRATE ME
    end

    create_table :task_results do
      primary_key :id

      foreign_key :project_id, :null=>false
      foreign_key :logger_id, :null=>false
      foreign_key :base_entity_id, :null=>false
      foreign_key :scan_result_id, :null=>true

      #Integer :id
      #Integer :logger_id
      #Integer :project_id
      #Integer :base_entity_id
      #Integer :scan_result_id
      String :name, :size => 400
      String :task_name, :size => 200
      DateTime :timestamp_start
      DateTime :timestamp_end
      String :options, :text => true
      String :handlers, :text => true
      FalseClass :complete
      String :job_id
      Integer :depth

      # MIGRATE ME
      #belongs_to :logger, 'Intrigue::Model::Logger'
      #belongs_to :project, :default => lambda { |r, p| Intrigue::Model::Project.first }
      #belongs_to :base_entity, 'Intrigue::Model::Entity'
      #belongs_to :scan_result, 'Intrigue::Model::ScanResult', :required => false
      # DONE has n, :entities, :through => Resource #, :constraint => :destroy
      # END MIGRATE ME
    end

    create_table :task_results_scan_results do
      primary_key :id
      Integer :scan_result_id
      Integer :task_result_id
    end

  end
end
