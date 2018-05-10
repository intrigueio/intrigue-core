Sequel.migration do
  change do

    alter_table(:entities) do
      add_index :project_id
    end

  end
end
