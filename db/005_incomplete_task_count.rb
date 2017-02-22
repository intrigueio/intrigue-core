Sequel.migration do
  change do

    alter_table :scan_results do
      add_column :incomplete_task_count, Integer
    end

  end
end
