Sequel.migration do
  change do

    alter_table(:entities) do
      add_index :project_id
      drop_index :id
    end

  end
end
