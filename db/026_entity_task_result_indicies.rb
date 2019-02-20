Sequel.migration do
  change do

    alter_table(:entities) do
      add_index [:alias_group_id,:project_id]
    end

    alter_table(:task_results) do
      add_index [:task_name,:project_id]
    end

    alter_table(:entities_task_results) do
      add_index :entity_id
      add_index :task_result_id
    end

  end
end
