Sequel.migration do
  change do

    alter_table(:task_results) do
      add_index :project_id
      add_index :scan_result_id
      add_index :base_entity_id
    end

  end
end
