Sequel.migration do
  change do
    drop_table :signals
    drop_table :signals_entities
  end
end
