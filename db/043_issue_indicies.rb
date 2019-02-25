Sequel.migration do

  change do
    alter_table :issues do
      add_index [:entity_id]
      add_index [:project_id]
      add_index [:task_result_id]
    end
  end

end

