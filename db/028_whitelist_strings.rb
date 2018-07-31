Sequel.migration do
  change do

    alter_table(:scan_results) do
      drop_column :filter_strings
      add_column :whitelist_strings, String, :text => true
      add_column :blacklist_strings, String, :text => true
    end

  end
end
