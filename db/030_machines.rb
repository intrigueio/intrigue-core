Sequel.migration do
  change do

    alter_table(:scan_results) do
      drop_column :strategy
      add_column :machine, String
    end

  end
end
