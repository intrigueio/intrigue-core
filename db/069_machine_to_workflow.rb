Sequel.migration do
  change do

    alter_table :scan_results do
      rename_column :machine, :workflow
    end

    alter_table :workflows do
      rename_column :default_depth,  :depth
      add_column :flow, String, :default =>  "recursive"
    end

  end
end