Sequel.migration do
  change do
    alter_table(:entities) do
      add_column :deleted, FalseClass, :default => false
    end
  end
end
