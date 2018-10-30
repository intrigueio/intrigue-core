Sequel.migration do
  change do

    alter_table(:task_results) do
      add_column :auto_scope, FalseClass, :default=>false
    end

  end
end
