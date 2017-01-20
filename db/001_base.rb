Sequel.migration do
  change do
    create_table :entities do
      primary_key :id
      foreign_key :project_id, :null => false

      String :type
      String :name, :size => 400
      String :details, :text => true
      FalseClass :deleted, :default => false
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
      FalseClass :graph_generation_in_progress, default: false
      FalseClass :complete, default: false
      String :handlers, :text => true
      String :options, :text => true
    end

    create_table :scan_results do
      primary_key :id

      foreign_key :project_id, :null => false
      foreign_key :logger_id, :null => false
      foreign_key :base_entity_id, :null => false

      String :name, :size => 400
      Integer :depth
      String :handlers, :text => true
      String :options, :text => true
      FalseClass :complete, default: false
      String :strategy
      String :filter_strings
    end

    create_table :task_results do
      primary_key :id

      foreign_key :project_id, :null => false
      foreign_key :logger_id, :null => false
      foreign_key :base_entity_id, :null => false
      foreign_key :scan_result_id, :null => true

      String :name, :size => 400
      String :task_name, :size => 200
      DateTime :timestamp_start
      DateTime :timestamp_end
      String :options, :text => true
      String :handlers, :text => true
      FalseClass :complete, default: false
      FalseClass :autoscheduled, default: true
      String :job_id
      Integer :depth
    end

    create_table :task_results_scan_results do
      primary_key :id
      Integer :scan_result_id
      Integer :task_result_id
    end

  end
end
