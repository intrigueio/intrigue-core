Sequel.migration do
  change do

    alter_table(:entities_task_results) do
      add_index [:entity_id,:task_result_id], unique: true 
    end

  end
end
