Sequel.migration do
  change do

    alter_table :task_results do
      add_column :handlers_complete, FalseClass, :default=>false
    end

    alter_table :scan_results do
      add_column :handlers_complete, FalseClass, :default=>false
    end
    
  end
end
