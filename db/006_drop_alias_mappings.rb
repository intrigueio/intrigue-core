Sequel.migration do
  change do
    drop_table :alias_mappings
  end
end
