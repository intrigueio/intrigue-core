Sequel.migration do
  change do

    create_table :findings do
      primary_key :id
      foreign_key :project_id, :null => false
      foreign_key :entity_id, :null => false
      foreign_key :task_result_id, :null => false
      foreign_key :scan_result_id
      String :type
      Integer :severity
      String :name, :size => 800
      String :details, :text => true
      FalseClass :resolved, :default => false
      FalseClass :deleted, :default => false
    end

  end
end
