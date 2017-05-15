Sequel.migration do
  change do

    alter_table(:task_results) do
      add_index :task_name
    end

  end
end
