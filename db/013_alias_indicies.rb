Sequel.migration do
  change do

    alter_table(:alias_mappings) do
      add_index :source_id
      add_index :target_id
    end

  end
end
