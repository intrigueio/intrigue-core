Sequel.migration do
  change do

    alter_table(:task_results) do
      add_column :task_type, String
    end

  end
end
