Sequel.migration do
  change do

    alter_table :task_results do
      add_column :canceled, FalseClass, :default=>false
    end

  end
end
