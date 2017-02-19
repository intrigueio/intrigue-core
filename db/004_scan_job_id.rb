Sequel.migration do
  change do

    alter_table :scan_results do
      add_column :job_id, String
    end

  end
end
