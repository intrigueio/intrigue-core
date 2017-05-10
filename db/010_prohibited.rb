Sequel.migration do
  change do

    alter_table(:entities) do
      add_column :prohibited, FalseClass, :default=>false
      add_column :enriched, FalseClass, :default=>false
    end

  end
end
